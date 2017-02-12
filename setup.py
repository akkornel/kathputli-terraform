#!/usr/bin/env python3

# Greet the user
print('''Hello!  This is the Kathputli bootstrap setup assistant!

It is an optional script that will help you choose the correct variables to
give to Terraform.

Although this script communicates with AWS, we're not making any changes.  We 
are only connecting to AWS in order to read data about the environments you can
access.  In addition, we'll make sure that you have valid AWS credentials.

Let's get started!
'''
)

# Make sure boto3 is available
try:
    print('First, we\'ll load the software we need to communicate with AWS...')
    import boto3
    import botocore
except:
    print('It appears that the boto3 module is not installed.',
          'The boto3 module is required to run this setup script.',
          'There are many ways to install boto3 (and its dependencies):',
          '* With pip, run `sudo pip3 install boto3`',
          '  (Or, for local install, do `pip3 install --user boto3`)',
          '* With HomeBrew, run `sudo brew install boto3`',
          '* With MacPorts, run `sudo port install py-boto3`',
          sep="\n")
    exit(1)
else:
    print('It looks like the software we need is available.  Great!')


session = boto3.session.Session()
terraform_vars = {}


# Test for valid credentials
try:
    print('Next, we\'ll see if we have valid AWS credentials...')
    s3 = session.client('s3', region_name='us-east-1')
    buckets = s3.list_buckets()
except botocore.exceptions.NoCredentialsError:
    print('It appears that you don\'t have any AWS credentials loaded.',
          '(At least, not where we can find them!)',
          'To load credentials, follow the instructions on this web page:',
          'http://boto3.readthedocs.io/en/latest/guide/configuration.html',
          "Once you're done, come back here and try again!",
          sep="\n")
    exit(1)
except botocore.exceptions.ClientError:
    print('It appears that, even with the credentials you have, I could not '
          'complete a simple "list buckets" operation.',
          'Please check your credentials to make sure they\'re valid.',
          'To load credentials, follow the instructions on this web page:',
          'http://boto3.readthedocs.io/en/latest/guide/configuration.html',
          "Once you're done, come back here and try again!",
          sep="\n")
    exit(1)
else:
    print('Your credentials look good!')

print('''Now we can actually get started!
''')

# Our needs: EC2, three AZs, SQS, KMS, EFS, SNS

# Get list of valid partitions
print('Fetching list of partitions.')
partitions = session.get_available_partitions()
region_partition_map = {}

# First, check for regions which have the services we need
valid_regions = []
valid_list_initialized = 0
print('Looking for regions that support: ', sep='', end='')
for service in ('ec2',):
    print('[', service, sep='', end='')
    candidates = []
    for partition in partitions:
        regions_in_partition = session.get_available_regions(service, 
            partition_name=partition) 
        candidates.extend(regions_in_partition)
        for region in regions_in_partition:
            region_partition_map[region] = partition
    if (valid_list_initialized == 0):
        valid_regions = candidates
        valid_list_initialized = 1
    else:
        for region in valid_regions:
            if region not in candidates:
                del valid_regions[valid_regions.index(region)]
    print(']', end='')
print("\n")

# Next, check for at least three AZs that are currently good.
print('Filtering out regions with less than three usable AZs:')
def region_has_3az(region):
    print(region, ': ', sep='', end='')
    try:
        client = session.client('ec2', region_name=region)
        az_list = client.describe_availability_zones(Filters=[{
            'Name': 'state',
            'Values': ['available']
        }])['AvailabilityZones']
    except botocore.exceptions.ClientError:
        print('BAD: Unable to fetch AZ list.  '
              'Maybe you can\'t access this partition?')
        return False
    else:
        if (len(az_list) < 3):
            print('BAD: Only available AZs are', [az['ZoneName'] for az in az_list])
            return False
        else:
            print('OK,', len(az_list), 'AZs')
            return True
valid_regions[:] = [region for region in valid_regions if
        region_has_3az(region)]
print('')

# Finally, valid_regions is an array of valid regions!
# Let's find out which region should be the primary region.
# Once chosen, remove it from the list of valid regions.
print('The following regions are available for bootstrapping:')
i=1
for region in valid_regions:
    print("\t%i: %s in the %s partition" % (i, region, 
        region_partition_map[region]))
    i = i+1
while 1:
    try:
        primary_region_index = int(input('Please choose a region for your '
            'primary region: '))
        primary_region_index -= 1
        primary_region = valid_regions[primary_region_index]
    except (EOFError, KeyboardInterrupt):
        print('')
        exit()
    except:
        print('You entered an invalid number.  '
              'Try again or use Control-D (on Windows, Control-Z) to exit.')
    else:
        print('Using region', primary_region, 'as the primary region.')
        terraform_vars['home_region'] = primary_region
        del valid_regions[primary_region_index]
        break

# Now, choose a backup region
print('''
You have the option of placing Puppet masters in a second region, which will be used as a backup.

This will _only_ be used for Puppet masters, and the things needed to support 
them (like files from S3, and AMIs to boot them).  Ancillary items (like the 
Puppet CAs) will only exist in the primary region.  This means a major, 
region-wide outage will impact the ability to enroll new Puppet clients, and to 
push out new Puppet code, but existing systems will still be able to 
communicate with Puppet in the backup region.

Also, note that each region will have at least three Puppet masters running, 
one in each AZ, so redundancy is already pretty high, as long as there is no 
region-wide outage.

The following regions qualify as a backup region:
''',
      "\t0: No backup region",
      sep="\n")
i=1
for region in valid_regions:
    print("\t%i: %s in the %s partition" % (i, region, 
        region_partition_map[region]))
    i = i+1
while 1:
    try:
        backup_region_index = int(input('Please choose a region for your '
            'backup region: '))
        backup_region_index -= 1
        backup_region = ('none' if backup_region_index == -1 else
                valid_regions[backup_region_index])
    except (EOFError, KeyboardInterrupt):
        print('')
        exit()
    except:
        print('You entered an invalid number.  '
        'Try again or use Control-D (on Windows, Control-Z) to exit.')
    else:
        print('Using region', backup_region, 'as the backup region.')
        terraform_vars['remote_region'] = backup_region
        break

# Clean up from region selection
del valid_regions, valid_list_initialized, region_partition_map


