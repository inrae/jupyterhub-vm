# CMake generated Testfile for 
# Source directory: /tmp/libgit2-0.27.4/tests
# Build directory: /vagrant/ansible/tests
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(libgit2_clar "/vagrant/ansible/libgit2_clar" "-ionline" "-xclone::local::git_style_unc_paths" "-xclone::local::standard_unc_paths_are_written_git_style")
add_test(libgit2_clar-proxy_credentials "/vagrant/ansible/libgit2_clar" "-v" "-sonline::clone::proxy_credentials_in_url" "-sonline::clone::proxy_credentials_request")
add_test(libgit2_clar-ssh "/vagrant/ansible/libgit2_clar" "-v" "-sonline::push" "-sonline::clone::ssh_cert" "-sonline::clone::ssh_with_paths")
