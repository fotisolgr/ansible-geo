#!/bin/bash
# GitLab Configuration Discovery Script
# Run this script on your existing GitLab servers to gather configuration details
# needed for the Ansible playbook

echo "========================================"
echo "  GitLab Configuration Discovery"
echo "========================================"
echo ""

echo "External URL:"
grep "^external_url" /etc/gitlab/gitlab.rb 2>/dev/null || echo "  Not configured"
echo ""

echo "GitLab Version:"
cat /opt/gitlab/version-manifest.txt 2>/dev/null | head -n 1 || gitlab-rake gitlab:env:info 2>/dev/null | grep "GitLab" || echo "  Unable to determine"
echo ""

echo "GitLab Edition:"
if [ -f /opt/gitlab/version-manifest.txt ]; then
    grep -q "gitlab-ee" /opt/gitlab/version-manifest.txt 2>/dev/null && echo "  Enterprise Edition (EE)" || echo "  Community Edition (CE)"
else
    echo "  Unable to determine"
fi
echo ""

echo "Geo Node Name:"
grep "geo_node_name" /etc/gitlab/gitlab.rb 2>/dev/null || echo "  Not configured"
echo ""

echo "PostgreSQL Configuration:"
echo "  Listen Address:"
grep "postgresql\['listen_address'\]" /etc/gitlab/gitlab.rb 2>/dev/null || echo "    Not configured (default: localhost)"
echo "  Shared Preload Libraries:"
grep "postgresql\['shared_preload_libraries'\]" /etc/gitlab/gitlab.rb 2>/dev/null || echo "    Not configured"
echo "  MD5 Auth CIDR:"
grep "postgresql\['md5_auth_cidr_addresses'\]" /etc/gitlab/gitlab.rb 2>/dev/null || echo "    Not configured"
echo ""

echo "Geo Configuration:"
grep -E "geo_(primary|secondary)_role" /etc/gitlab/gitlab.rb 2>/dev/null || echo "  Geo not configured"
echo ""

echo "Server IP Addresses:"
hostname -I | tr ' ' '\n' | sed 's/^/  /'
echo ""

echo "Hostname:"
echo "  $(hostname -f)"
echo ""

echo "License Status:"
gitlab-rails runner "begin; license = License.current; puts '  Plan: ' + (license&.plan || 'No license'); puts '  Expires: ' + (license&.expires_at&.to_s || 'N/A'); rescue => e; puts '  Error checking license: ' + e.message; end" 2>/dev/null || echo "  Unable to check license status"
echo ""

echo "Database Password (hashed):"
grep "gitlab_rails\['db_password'\]" /etc/gitlab/gitlab.rb 2>/dev/null | sed 's/=.*/= [REDACTED]/' || echo "  Not explicitly set (using default)"
echo ""

echo "GitLab Secrets File:"
if [ -f /etc/gitlab/gitlab-secrets.json ]; then
    echo "  Exists: Yes"
    echo "  Location: /etc/gitlab/gitlab-secrets.json"
    echo "  Note: This file must be copied to secondary nodes"
else
    echo "  Exists: No"
    echo "  Note: Secrets file will be generated on first reconfigure"
fi
echo ""

echo "========================================"
echo "  Discovery Complete"
echo "========================================"
echo ""
echo "Use this information to configure your Ansible inventory and variables."
