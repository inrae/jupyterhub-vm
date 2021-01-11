file(REMOVE_RECURSE
  "../libgit2.pdb"
  "../libgit2.so.0.27.4"
  "../libgit2.so"
  "../libgit2.so.27"
)

# Per-language clean rules from dependency scanning.
foreach(lang C)
  include(CMakeFiles/git2.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
