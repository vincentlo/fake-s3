require 'test/test_helper'
require 'fileutils'

class S3CmdTest < Test::Unit::TestCase
  def setup
    config = File.expand_path(File.join(File.dirname(__FILE__),'local_s3_cfg'))
    raise "Please install s3cmd" if `which s3cmd`.empty?
    @s3cmd = "s3cmd --config #{config}"
  end

  def teardown
  end

  def test_create_bucket
    `#{@s3cmd} mb s3://s3cmd_bucket`
    output = `#{@s3cmd} ls`
    assert_match(/s3cmd_bucket/,output)
  end

  def test_store
    File.open(__FILE__,'rb') do |input|
      File.open("/tmp/fakes3_upload",'wb') do |output|
        output << input.read
      end
    end
    output = `#{@s3cmd} put /tmp/fakes3_upload s3://s3cmd_bucket/upload`
    assert_match(/stored/,output)

    FileUtils.rm("/tmp/fakes3_upload")
  end

  def test_acl
    File.open(__FILE__,'rb') do |input|
      File.open("/tmp/fakes3_acl_upload",'wb') do |output|
        output << input.read
      end
    end
    output = `#{@s3cmd} put /tmp/fakes3_acl_upload s3://s3cmd_bucket/acl_upload`
    assert_match(/stored/,output)

    output = `#{@s3cmd} --force setacl -P s3://s3cmd_bucket/acl_upload`
  end

  def test_large_store
  end

  def test_multi_directory
  end

  def test_intra_bucket_copy
  end

  def test_metadata_store
    assert_equal true, Bucket.create("ruby_aws_s3")
    bucket = Bucket.find("ruby_aws_s3")

    # Note well: we can't seem to access obj.metadata until we've stored
    # the object and found it again. Thus the store, find, store
    # runaround below.
    obj = bucket.new_object(:value => "foo")
    obj.key = "key_with_metadata"
    obj.store
    obj = S3Object.find("key_with_metadata", "ruby_aws_s3")
    obj.metadata[:param1] = "one"
    obj.metadata[:param2] = "two, three"
    obj.store
    obj = S3Object.find("key_with_metadata", "ruby_aws_s3")

    assert_equal "one", obj.metadata[:param1]
    assert_equal "two, three", obj.metadata[:param2]
  end

  def test_metadata_copy
    assert_equal true, Bucket.create("ruby_aws_s3")
    bucket = Bucket.find("ruby_aws_s3")

    # Note well: we can't seem to access obj.metadata until we've stored
    # the object and found it again. Thus the store, find, store
    # runaround below.
    obj = bucket.new_object(:value => "foo")
    obj.key = "key_with_metadata"
    obj.store
    obj = S3Object.find("key_with_metadata", "ruby_aws_s3")
    obj.metadata[:param1] = "one"
    obj.metadata[:param2] = "two, three"
    obj.store

    S3Object.copy("key_with_metadata", "key_with_metadata2", "ruby_aws_s3")
    obj = S3Object.find("key_with_metadata2", "ruby_aws_s3")

    assert_equal "one", obj.metadata[:param1]
    assert_equal "two, three", obj.metadata[:param2]
  end
end
