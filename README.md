# GitLab Geo Ansible Playbook

Automate GitLab Geo configuration for existing GitLab Enterprise Edition installations.

## Overview

GitLab Geo allows you to replicate your GitLab instance to one or more geographical locations, providing:
- Disaster recovery capabilities
- Reduced latency for distributed teams
- Read-only secondary instances that can serve Git operations

This playbook is designed for **existing GitLab installations**. It will:
- Configure Geo on your current primary server (with data/repositories)
- Set up a secondary server to replicate from the primary
- NOT reinstall GitLab or disrupt your existing setup

## Prerequisites

- Two servers running Ubuntu/Debian or RHEL/CentOS
- Root or sudo access on both servers
- GitLab Enterprise Edition license (Geo is an EE feature)
- Ansible 2.9 or higher installed on your control machine
- Network connectivity between primary and secondary nodes

## Directory Structure

```
.
├── inventory.ini                    # Inventory file with host definitions
├── site.yml                         # Main playbook for Geo configuration
├── ansible.cfg                      # Ansible configuration
├── gather-gitlab-info.sh            # Discovery script for existing GitLab servers
├── roles/
│   ├── gitlab_primary/              # Primary node Geo configuration
│   │   ├── defaults/main.yml        # Default variables
│   │   ├── tasks/main.yml           # Configuration tasks
│   │   └── handlers/main.yml        # Handler definitions
│   └── gitlab_secondary/            # Secondary node Geo configuration
│       ├── defaults/main.yml        # Default variables
│       ├── tasks/main.yml           # Configuration tasks
│       └── handlers/main.yml        # Handler definitions
├── group_vars/                      # Group variables directory
└── host_vars/                       # Host-specific variables directory
```

## Configuration

### 1. Update Inventory

Edit `inventory.ini` to match your environment:

```ini
[gitlab_primary]
primary.example.com ansible_host=YOUR_PRIMARY_IP ansible_user=root

[gitlab_secondary]
secondary.example.com ansible_host=YOUR_SECONDARY_IP ansible_user=root
```

### 2. Configure Variables

Update the following variables in the inventory file or create host-specific variable files:

- `gitlab_external_url`: External URL for GitLab
- `gitlab_geo_primary_external_url`: Primary node URL
- `gitlab_geo_secondary_external_url`: Secondary node URL
- `gitlab_db_password`: Database password (change from default)

You can also override defaults by creating files in `host_vars/` or `group_vars/`.

### 3. Discover Existing GitLab Configuration

If you have existing GitLab EE servers and need to gather configuration details, use the included discovery script:

```bash
# Copy the script to your GitLab server
scp gather-gitlab-info.sh root@your-gitlab-server:/tmp/

# SSH to the server and run it
ssh root@your-gitlab-server
chmod +x /tmp/gather-gitlab-info.sh
/tmp/gather-gitlab-info.sh
```

The script will display:
- Current external URL
- GitLab version and edition (EE/CE)
- Geo configuration (if already set up)
- PostgreSQL settings
- Server IP addresses and hostname
- License status
- Database configuration

Use this information to populate your `inventory.ini` and role variables.

#### Key Configuration Files on Existing GitLab Servers

- **Main config**: `/etc/gitlab/gitlab.rb`
- **Secrets**: `/etc/gitlab/gitlab-secrets.json` (must be copied to secondary)
- **Version info**: `/opt/gitlab/version-manifest.txt`

### 4. Important Security Notes

Before running the playbook:

1. Change the default database password in the inventory or role defaults
2. Ensure proper firewall rules are in place
3. Configure SSL/TLS certificates for HTTPS access
4. Review and adjust PostgreSQL access controls

## Usage

### Step 1: Update Configuration Variables

Edit `roles/gitlab_primary/defaults/main.yml`:
```yaml
gitlab_geo_node_name: "primary"
postgresql_replication_password: "CHANGE_THIS_STRONG_PASSWORD"
```

Edit `roles/gitlab_secondary/defaults/main.yml`:
```yaml
gitlab_geo_node_name: "secondary"
gitlab_primary_db_host: "your-primary-hostname-or-ip"
postgresql_replication_password: "SAME_PASSWORD_AS_PRIMARY"
```

### Step 2: Configure Primary Node

```bash
ansible-playbook -i inventory.ini site.yml --limit gitlab_primary
```

This will:
- Backup your current configuration to `/root/gitlab-config-backups/`
- Add Geo settings to `/etc/gitlab/gitlab.rb`
- Configure PostgreSQL for replication
- Set the node as primary
- Reconfigure GitLab

### Step 3: Copy Secrets to Secondary

After primary configuration completes:

```bash
# Copy secrets from primary to secondary
scp root@PRIMARY_HOST:/etc/gitlab/gitlab-secrets.json /tmp/
scp /tmp/gitlab-secrets.json root@SECONDARY_HOST:/etc/gitlab/
```

### Step 4: Configure Secondary Node

```bash
ansible-playbook -i inventory.ini site.yml --limit gitlab_secondary
```

This will:
- Backup current configuration
- Add Geo secondary settings
- Configure database connection to primary
- Reconfigure GitLab

### Step 5: Register Secondary in Primary UI

1. Log into your **primary** GitLab as admin
2. Go to **Admin Area → Geo → Nodes**
3. Click **"New site"** or **"Add site"**
4. Enter secondary details:
   - **Name**: secondary (or your custom name)
   - **URL**: Your secondary's external URL
5. Click **Save**

### Step 6: Complete Secondary Setup

SSH to secondary and run:

```bash
gitlab-ctl reconfigure
gitlab-rake geo:db:create
gitlab-rake geo:db:migrate
gitlab-ctl restart
```

### Step 7: Verify Geo Status

On the primary node:

```bash
gitlab-rake geo:status
```

You should see replication status for your secondary node.

## Troubleshooting

### Check GitLab Status

```bash
gitlab-ctl status
```

### View Logs

```bash
gitlab-ctl tail
```

### Check Geo Configuration

```bash
gitlab-rake gitlab:geo:check
```

### Database Replication Issues

Check PostgreSQL logs:

```bash
gitlab-ctl tail postgresql
```

Verify replication user exists:

```bash
gitlab-psql -c "SELECT * FROM pg_user WHERE usename = 'gitlab_replicator';"
```

## Maintenance

### Update GitLab

To update GitLab on both nodes:

```bash
ansible-playbook -i inventory.ini site.yml
```

Always update the primary node first, then the secondary nodes.

### Backup

Backup the primary node regularly:

```bash
gitlab-backup create
```

## License Requirements

GitLab Geo is available only in GitLab Enterprise Edition. Ensure you have a valid license installed before configuring Geo.

## Additional Resources

- [GitLab Geo Documentation](https://docs.gitlab.com/ee/administration/geo/)
- [GitLab Omnibus Documentation](https://docs.gitlab.com/omnibus/)
- [Disaster Recovery](https://docs.gitlab.com/ee/administration/geo/disaster_recovery/)

## Support

For issues related to:
- This playbook: Open an issue in this repository
- GitLab Geo: Consult [GitLab documentation](https://docs.gitlab.com/ee/administration/geo/)
- GitLab support: Contact GitLab support if you have an active subscription
