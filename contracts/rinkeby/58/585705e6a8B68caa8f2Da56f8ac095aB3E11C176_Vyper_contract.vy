# SPDX-License-Identifier: MIT
# @version ^0.3.3

my_var: public(uint256)

@external
def update_var(my_new_var: uint256):
    self.my_var = my_new_var