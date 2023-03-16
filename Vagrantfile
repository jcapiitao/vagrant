require 'vagrant-openstack-provider'

servers=[
  {
    :hostname => "c8",
    :image => "CentOS-Stream-8-x86_64-GenericCloud",
    :username => "centos",
    :flavor => "ci.m1.large",
  },
  {
    :hostname => "packstack-c8",
    :image => "CentOS-Stream-8-x86_64-GenericCloud",
    :username => "centos",
    :flavor => "ci.memory.large",
  },
  {
    :hostname => "crc-okd-c9",
    :image => "CentOS-Stream-GenericCloud-9-20220202.0",
    :username => "cloud-user",
    :flavor => "ci.memory.large",
  },
  {
    :hostname => "crc-okd-c9-1",
    :image => "CentOS-Stream-GenericCloud-9-20220202.0",
    :username => "cloud-user",
    :flavor => "ci.memory.large",
  },
  {
    :hostname => "c9",
    :image => "CentOS-Stream-GenericCloud-9-20220202.0",
    :username => "cloud-user",
    :flavor => "ci.m1.large",
  },
  {
    :hostname => "c7",
    :image => "CentOS-7-x86_64-GenericCloud-released-latest",
    :username => "centos",
    :flavor => "ci.m1.large",
  },
  {
    :hostname => "f37",
    :image => "Fedora-Cloud-Base-37-latest",
    :username => "fedora",
    :flavor => "ci.m1.xlarge",
  }
]

Vagrant.configure(2) do |config|

    servers.each do |machine|
        config.vm.define machine[:hostname] do |node|
            node.vm.boot_timeout = 3600
            node.vm.hostname = machine[:hostname]
            node.vm.network "private_network", ip: machine[:ip]
            node.vm.provider :openstack do |os, override|
                override.ssh.username = machine[:username]
                override.ssh.private_key_path = '~/.ssh/id_ed25519'
                override.nfs.functional = false

                # Specify OpenStack authentication information
                os.identity_api_version = ENV['OS_IDENTITY_API_VERSION']
                os.project_name = ENV['OS_PROJECT_NAME']
                os.project_domain_name = ENV['OS_USER_DOMAIN_NAME']
                os.user_domain_name = ENV['OS_USER_DOMAIN_NAME']
                os.openstack_auth_url = ENV['OS_AUTH_URL']
                os.username = ENV['OS_USERNAME']
                os.password = ENV['OS_PASSWORD']
                os.networks = ENV['OS_NETWORKS']
                os.security_groups = ['Allow All']
#               os.floating_ip_pool = ENV['OS_FLOATING_IP_POOL']
                os.keypair_name = "id-rsa"

                # Specify instance information
                os.server_name = "jcapitao-" + machine[:hostname]
                os.flavor = machine[:flavor]
                os.image = machine[:image]
            end

            node.vm.provision "base", type: "ansible", run: "once" do |ansible|
                ansible.verbose = false
                ansible.playbook = "playbook.yml"
                ansible.tags = "base"
                ansible.compatibility_mode = "2.0"
            end

            node.vm.provision "weirdo", type: "ansible", run: "never" do |ansible|
                ansible.verbose = false
                ansible.playbook = "playbook.yml"
                ansible.tags = "weirdo"
                ansible.compatibility_mode = "2.0"
            end

            node.vm.provision "packstack", type: "ansible", run: "never" do |ansible|
                ansible.verbose = false
                ansible.playbook = "playbook.yml"
                ansible.tags = "packstack"
                ansible.compatibility_mode = "2.0"
            end

            node.vm.provision "dlrn", type: "ansible", run: "never" do |ansible|
                ansible.verbose = false
                ansible.playbook = "playbook.yml"
                ansible.tags = "dlrn"
                ansible.compatibility_mode = "2.0"
            end

            node.vm.provision "okd", type: "ansible", run: "never" do |ansible|
                ansible.verbose = false
                ansible.playbook = "playbook.yml"
                ansible.tags = "okd"
                ansible.compatibility_mode = "2.0"
            end
        end
    end


end
