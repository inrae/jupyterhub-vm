## Using your S3 storage as a Vagrant box registry

<br>

The following example shows how to use an S3-compatible object storage as a private Vagrant box registry. The S3 objects are private. Vagrant accesses them using AWS credentials and pre-signed URLs.

* Example S3 storage

    * Storage: NetApp StorageGRID 11.9
    * S3 endpoint: https://s3-data.meso.umontpellier.fr
    * Bucket: bibs6
    * Base path: djacob/boxes
    * AWS region: us-east-1
    * Vagrant provider: virtualbox

<br>

### 1 - Installation of the fixed `vagrant-box-s3` plugin

This project uses a patched version of the [`vagrant-box-s3`](https://github.com/djacob65/vagrant-box-s3) plugin. The patch adds support for S3-compatible storage endpoints (such as NetApp StorageGRID) and handles `metadata.json` correctly.

In particular, the plugin:
- supports a custom S3 endpoint through `AWS_ENDPOINT_URL`;
- uses AWS credentials from the standard AWS configuration;
- generates pre-signed S3 URLs for private objects;
- handles Vagrant's `HEAD` request for `metadata.json` by performing a signed `GET` request instead. This is required because the StorageGRID endpoint used in this example returns `403 Forbidden` for pre-signed `HEAD` requests.

* On Windows/Cygwin, you must first create two symbolic links to compile the Ruby code :

    ```
    ln -s /cygdrive/c/Program\ Files/Vagrant/embedded/mingw64/bin/gem.cmd /usr/local/bin/gem
    ln -s /cygdrive/c/Program\ Files/Vagrant/embedded/mingw64/bin/ruby.exe /usr/local/bin/ruby.exe
    ```

* Clone the patched plugin repository and build the Ruby gem:

    ```
    git clone https://github.com/djacob65/vagrant-box-s3.git
    
    cd vagrant-box-s3
    
    git checkout v0.1.5
    
    gem build vagrant-box-s3.gemspec
    ```

* Install the locally built plugin:

    ```
    vagrant plugin install ./vagrant-box-s3-0.1.5.gem
    ```

<br>

### 2 - AWS Amazon tool

* You must install the **_aws_** tool :

    ```
    pip3 install aws
    ```

* Put the keys in **_$HOME/.aws/credentials_** (_/cygdrive/c/Users/\<user>/credentials_ on Windows/Cygwin) :

    ```
    [default]
    aws_access_key_id = ...
    aws_secret_access_key = ...
    ```

* Put **_endpoint_** and **_region_** in **_$HOME/.aws/config_** (_/cygdrive/c/Users/\<user>/config_ on Windows/Cygwin) :

    ```
    [default]
    region = us-east-1
    endpoint_url = https://s3-data.meso.umontpellier.fr
    ```

<br>

### 3 - Build the Vagrant box then push it into your S3 storage

* **Build the Vagrant box**
 
    The Vagrant box is first built locally using Packer:

    ```
    mkdir builds
    packer build box-config.json
    ```

    This produces the .box archive in the local _builds/_ directory.


* **Add the Vagrant box to the local Vagrant registry**

    Before uploading the box to S3, add it to the local Vagrant box registry:

    ```
    vagrant box add "djreg/small-ubuntu2204" --provider virtualbox ./builds/small-ubuntu2204.box
    ```

    This allows the migration script to retrieve the box using the standard Vagrant box management commands.

* **Push the Vagrant box from the local registry to S3**

    The migration script exports the box from the local Vagrant registry, calculates its SHA256 checksum, uploads the .box file, and generates the corresponding metadata.json.

    ```
    sh ./migrate-vagrant-boxes-to-s3.sh \
        -b bibs6 \
        -p djacob/boxes \
        -v 1.1 \
        -e https://s3-data.meso.umontpellier.fr
    ```

    The main parameters are:

    * -b: S3 bucket
    * -p: base path inside the bucket
    * -v: Vagrant box version to publish
    * -e: custom S3 endpoint

    The script uses path-style S3 URLs because the storage is an S3-compatible endpoint rather than Amazon S3.

* **Output**

    Example output:

    ```
    [migrate] Temporary working directory: ./vagrant-s3-migration.Q5eI0Y
    [migrate] Target bucket: s3://bibs6/djacob/boxes/
    [migrate] Custom S3 endpoint: https://s3-data.meso.umontpellier.fr (style: path-style)
    [migrate] Reading the list of local boxes (vagrant box list)...
    [migrate] ----------------------------------------------------------------
    [migrate] Box: djreg/small-ubuntu2204  |  provider: virtualbox  |  version: 0
    [migrate] Final name on S3/registry: djreg/small-ubuntu2204
    [migrate] Exporting (repackage) the box to ./vagrant-s3-migration.Q5eI0Y/djreg-small-ubuntu2204-0-virtualbox.box ...
    [migrate] SHA256: b5baff70170a4f67659c0c4e378f3b8713230f76e32f9e99d547a1bf83b45ab6
    [migrate] Uploading to s3://bibs6/djacob/boxes/djreg/small-ubuntu2204/1.1/virtualbox.box ...
    upload: vagrant-s3-migration.Q5eI0Y\djreg-small-ubuntu2204-0-virtualbox.box to s3://bibs6/djacob/boxes/djreg/small-ubuntu2204/1.1/virtualbox.box
    [migrate] ================================================================
    [migrate] Generating metadata files...
    [migrate] Metadata for 'djreg/small-ubuntu2204' -> s3://bibs6/djacob/boxes/djreg/small-ubuntu2204/metadata.json
    upload: vagrant-s3-migration.Q5eI0Y\djreg-small-ubuntu2204-metadata.json to s3://bibs6/djacob/boxes/djreg/small-ubuntu2204/metadata.json
    [migrate] ================================================================
    [migrate] Migration to S3 complete.
    ```

* **File tree structure on S3 storage**

    The migration script creates the following structure:

    ```
    StorageGRID 11.9
         │
         └── bibs6/
              └── djacob/boxes/
                   └── djreg/
                        └── small-ubuntu2204/
                             ├── metadata.json
                             └── 1.1/
                                  └── virtualbox.box
    ```


* **_metadata.json_**

    The metadata.json file acts as the Vagrant box registry metadata. It describes the box name, available versions, providers, download URL, and checksum.

    ```
    {
      "name": "djreg/small-ubuntu2204",
      "versions": [
        {
          "version": "1.1",
          "providers": [
            {
              "name": "virtualbox",
              "url": "https://s3-data.meso.umontpellier.fr/bibs6/djacob/boxes/djreg/small-ubuntu2204/1.1/virtualbox.box",
              "checksum_type": "sha256",
              "checksum": "b5baff70170a4f67659c0c4e378f3b8713230f76e32f9e99d547a1bf83b45ab6"
            }
          ]
        }
      ]
    }
    ```

<br>


### 4 - Get the box from your S3 storage into the local registry


The box can now be installed from the private S3 storage. The AWS configuration must provide the credentials and the S3 endpoint. The AWS credentials should not be stored in the Vagrantfile. They should be provided through the standard AWS configuration. See point 2 above.


* For example:

    ```
    export AWS_PROFILE=default
    export AWS_ENDPOINT_URL=https://s3-data.meso.umontpellier.fr
    export AWS_REGION=us-east-1
    ```


* Remove previous box from the local registry before

    ```
    $ vagrant box remove djreg/small-ubuntu2204
    ```
    ```
    Removing box 'djreg/small-ubuntu2204' (v0) with provider 'virtualbox'...
    ```

* Add box to the local registry before

    The box can then be added from its _metadata.json_:

    ```
    vagrant box add --provider=virtualbox \
         "https://s3-data.meso.umontpellier.fr/bibs6/djacob/boxes/djreg/small-ubuntu2204/metadata.json"
    ```

    The vagrant-box-s3 plugin authenticates the private S3 objects by generating AWS Signature Version 4 pre-signed URLs.


* The corresponding **Workflow**

    ```
    Vagrant 2.4.9
         │
         │ box_url → metadata.json
         ▼
    vagrant-box-s3 0.1.5
         │
         ├── AWS_PROFILE=default
         ├── AWS_REGION=us-east-1
         └── AWS_ENDPOINT_URL=https://s3-data.meso.umontpellier.fr
         │
         ▼
    AWS SDK for Ruby
         │
         │ AWS Signature Version 4
         │ pre-signed URL
         ▼
    StorageGRID 11.9
         │
         ├── GET metadata.json
         │
         └── GET virtualbox.box
    ```


* **Note about HEAD requests**

    Vagrant normally performs a HEAD request to check the remote object before downloading it.  With the StorageGRID endpoint used in this example, a pre-signed HEAD request returns 403 Forbidden, while a pre-signed GET request works correctly. The patched vagrant-box-s3 plugin therefore intercepts the HEAD operation for metadata.json and performs a signed GET request instead. This allows Vagrant to use the private StorageGRID objects without making them publicly accessible.

<br>


### 5 - Using the Vagrantfile


You can also configure the Vagrantfile to fetch the box into the local registry without a preliminary step, as described above (`vagrant box add ...`). Indeed, once the plugin is installed and the AWS environment is configured, the Vagrantfile only needs to reference the box name and its metadata.json.


* _Vagrantfile_

    ```    
    ENV['AWS_PROFILE'] = 'default'
    ENV['AWS_ENDPOINT_URL']='https://s3-data.meso.umontpellier.fr'
    BOX_PATH="bibs6/djacob/boxes"
    BOX_NAME = "djreg/small-ubuntu2204"

    Vagrant.configure("2") do |config|
    
      config.vm.box = BOX_NAME
      config.vm.box_url = "#{ENV['AWS_ENDPOINT_URL']}/#{BOX_PATH}/#{BOX_NAME}/metadata.json"
    
    end
    ```

    The AWS credentials are deliberately not included in the Vagrantfile. Vagrant uses the default AWS profile and the patched vagrant-box-s3 plugin generates the required pre-signed URLs.

* The VM can then be started normally:

    ```
    $ vagrant up
    ```

* Example output:
    ```
    Bringing machine 'default' up with 'virtualbox' provider...
    ==> default: Box 'djreg/small-ubuntu2204' could not be found. Attempting to find and install...
        default: Box Provider: virtualbox
        default: Box Version: >= 0
    ==> default: Loading metadata for box 'https://s3-data.meso.umontpellier.fr/bibs6/djacob/boxes/djreg/small-ubuntu2204/metadata.json'
        default: URL: https://s3-data.meso.umontpellier.fr/bibs6/djacob/boxes/djreg/small-ubuntu2204/metadata.json
    ==> default: Adding box 'djreg/small-ubuntu2204' (v1.1) for provider: virtualbox
        default: Downloading: https://s3-data.meso.umontpellier.fr/bibs6/djacob/boxes/djreg/small-ubuntu2204/1.1/virtualbox.box
        default:
        default: Calculating and comparing box checksum...
    ==> default: Successfully added box 'djreg/small-ubuntu2204' (v1.1) for 'virtualbox'!
    ==> default: Importing base box 'djreg/small-ubuntu2204'...
    ==> default: Matching MAC address for NAT networking...
    ==> default: Checking if box 'djreg/small-ubuntu2204' version '1.1' is up to date...
    ==> default: Setting the name of the VM: s3_migrate_default_1786624437774_75460
    ==> default: Clearing any previously set network interfaces...
    ==> default: Preparing network interfaces based on configuration...
        default: Adapter 1: nat
    ==> default: Forwarding ports...
        default: 22 (guest) => 2222 (host) (adapter 1)
    ==> default: Booting VM...
    ==> default: Waiting for machine to boot. This may take a few minutes...
        default: SSH address: 127.0.0.1:2222
        default: SSH username: vagrant
        default: SSH auth method: private key
        default:
        default: Vagrant insecure key detected. Vagrant will automatically replace
        default: this with a newly generated keypair for better security.
        default:
        default: Inserting generated public key within guest...
        default: Removing insecure key from the guest if it is present...
        default: Key inserted! Disconnecting and reconnecting using new SSH key...
    ==> default: Machine booted and ready!
    ==> default: Checking for guest additions in VM...
    ==> default: Mounting shared folders...
        default: C:/VirtualMach/Vagrant/s3_migrate => /vagrant
    ```

* To stop and remove the test VM:

    ```
    vagrant halt -f default
    vagrant destroy -f default
    rm -rf ./.vagrant
    ```

### 6 - Without the patched `vagrant-box-s3` plugin

The patched `vagrant-box-s3` plugin is not required if the Vagrant box is first downloaded to the local filesystem.

* In this case, the workflow is:

    ```text
    S3 storage / Google Drive
              │
              │ manual download
              ▼
       Local .box file
              │
              ▼
           Vagrant
              │
              ▼
        VirtualBox VM
    ```

This approach can be useful as a fallback or for environments where the vagrant-box-s3 plugin cannot be installed. The main difference is that Vagrant does not access the remote storage directly. The .box file must first be downloaded locally.


#### i) Get the box on S3 storage

The box can be downloaded from the S3 storage using the AWS CLI.

* Using **aws**
    ```
    aws s3 cp 
       "s3://bibs6/djacob/boxes/dhreg/small-ubuntu2204/1.1/virtualbox.box" \
       ./builds/small-ubuntu2204.box
    ```

    The AWS CLI uses the credentials and S3 endpoint configured in the standard AWS configuration. For a private S3-compatible storage such as StorageGRID, the endpoint can be specified explicitly if it is not already defined in the AWS configuration:

    ```
    aws s3 cp \
       "s3://bibs6/djacob/boxes/djreg/small-ubuntu2204/1.1/virtualbox.box" \
       "./builds/small-ubuntu2204.box" \
       --endpoint-url https://s3-data.meso.umontpellier.fr
    ```

#### ii) Get the box on Google Drive

The same approach can be used with other storage services. For example, the box can be downloaded from Google Drive

* Using **gdown**

    install the Google tool  — written in _Python_ — as follows, if not yet installed :
    ```
    pip3 install gdown
    ```
    then :
    ```
    gdown -O ./builds/small-ubuntu2204.box 1QM-BXuCwH_YFc20jgtNXMYVH4hsqs1DE
    ```

    The -O option specifies the local destination of the downloaded .box file.

<br>

After the download, both S3 and Google Drive therefore provide the same local file:

```
./builds/small-ubuntu2204.box
```


#### iii) Vagrantfile

Once the .box file has been downloaded locally, Vagrant can use it directly through a file:// URL.


```
Vagrant.configure("2") do |config|
  config.vm.box = "small-ubuntu2204.box"
  config.vm.box_url = "file://#{File.expand_path("builds/small-ubuntu2204.box", __dir__)}"
end
```

The File.expand_path call converts the relative path to an absolute filesystem path. The __dir__ variable refers to the directory containing the Vagrantfile, so the configuration remains independent of the directory from which vagrant is executed.


#### Comparison with the patched S3 workflow


| Method                   | Remote storage accessed by Vagrant | Local `.box` required | Private S3 authentication |
| ------------------------ | ---------------------------------- | --------------------: | ------------------------: |
| Patched `vagrant-box-s3` | Yes                                |                    No |                       Yes |
| AWS CLI + local box      | No                                 |                   Yes |                       Yes |
| `gdown` + local box      | No                                 |                   Yes |                       N/A |

The patched vagrant-box-s3 approach is therefore more convenient when the box is intended to be used directly as a private S3-hosted Vagrant registry.

The local download approach remains useful when:

* the plugin cannot be installed;
* the storage provider is not supported directly;
* the box needs to be cached locally;
* or the same .box file needs to be reused several times without downloading it again.