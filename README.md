# GitLab Geo Ansible Playbook

This Ansible playbook automates the installation and configuration of GitLab Geo between two GitLab Omnibus instances.

## Overview

GitLab Geo allows you to replicate your GitLab instance to one or more geographical locations, providing:
- Disaster recovery capabilities
- Reduced latency for distributed teams
- Read-only secondary instances that can serve Git operations

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
├── site.yml                         # Main playbook
├── ansible.cfg                      # Ansible configuration
├── gather-gitlab-info.sh            # Discovery script for existing GitLab servers
├── roles/
│   ├── gitlab_primary/             # Primary node role
│   │   ├── defaults/main.yml       # Default variables
│   │   ├── tasks/main.yml          # Tasks for primary setup
│   │   ├── templates/gitlab.rb.j2  # GitLab configuration template
│   │   └── handlers/main.yml       # Handler definitions
│   └── gitlab_secondary/           # Secondary node role
│       ├── defaults/main.yml       # Default variables
│       ├── tasks/main.yml          # Tasks for secondary setup
│       ├── templates/gitlab.rb.j2  # GitLab configuration template
│       └── handlers/main.yml       # Handler definitions
├── group_vars/                     # Group variables directory
└── host_vars/                      # Host-specific variables directory
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

### Install Both Nodes

Run the complete playbook to set up both primary and secondary nodes:

```bash
ansible-playbook -i inventory.ini site.yml
```

### Install Only Primary Node

```bash
ansible-playbook -i inventory.ini site.yml --limit gitlab_primary
```

### Install Only Secondary Node

```bash
ansible-playbook -i inventory.ini site.yml --limit gitlab_secondary
```

## Post-Installation Steps

After running the playbook, complete these manual steps:

### 1. Configure Primary Node

The playbook automatically sets up the primary node. Verify the configuration:

```bash
ssh root@primary.example.com
gitlab-ctl status
```

### 2. Copy Secrets to Secondary

Copy the secrets file from primary to secondary:

```bash
# On primary node
cat /etc/gitlab/gitlab-secrets.json

# Copy the content to secondary node at the same path
```

### 3. Configure Secondary Node in GitLab UI

1. Log in to the primary node as admin
2. Go to Admin Area > Geo > Nodes
3. Click "Add site" or "New site"
4. Enter the secondary node details:
   - Name: secondary
   - URL: https://secondary.example.com
5. Save the configuration

### 4. Complete Secondary Setup

On the secondary node:

```bash
gitlab-ctl reconfigure
gitlab-rake geo:db:create
gitlab-rake geo:db:migrate
gitlab-ctl restart
```

### 5. Verify Geo Status

On the primary node, check Geo status:

```bash
gitlab-rake geo:status
```

Or check in the GitLab UI at Admin Area > Geo > Nodes.

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
