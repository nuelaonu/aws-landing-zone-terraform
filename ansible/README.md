# Ansible baseline

Configuration baseline for EC2 hosts that still need host-level
management alongside the Terraform landing zone.

**SSM-first note:** the preferred access and patching path is AWS
Systems Manager (Session Manager, Patch Manager, Inventory). This role
exists for the controls SSM does not set by itself — sshd hardening,
auditd rules, sysctl — and for fleets where an agent-based baseline is
still the audit evidence. The CloudWatch agent is opt-in
(`baseline_install_cloudwatch_agent`); log shipping via SSM / instance
roles is the default posture.

## Run (against the sample inventory)

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check
```

The sample inventory uses documentation IP addresses (192.0.2.0/24)
and example hostnames only.
