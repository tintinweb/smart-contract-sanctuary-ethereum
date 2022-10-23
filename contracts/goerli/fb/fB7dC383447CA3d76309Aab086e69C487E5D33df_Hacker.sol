/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

interface Secret {
     function submitApplication(string calldata contacts, bytes32 password1, bytes32 password2, bytes32 password3) external;
}

contract Hacker {
    string public name = "JustAgent";
    bytes32 res1 = 0xf1c362728569c488552c2828681f909dc6d72b7ade4f21bd9ba62e8e120d7c7e;
    bytes32 res2 = 0xa2f8626ec13e63bffbfcac6d503bbbee99f62c03b558773c561736fe19893e75;
    bytes32 res3 = 0xf60b445f2b2ffd4d8c63cadf55e46622b83edb6c4fe859c28b2cfe1ce212332b;

    Secret secret = Secret(0x7b95548D9B61A79B96260e4974AaA7B0FD1F52e1);

    function hack() public {
        secret.submitApplication(name, res1, res2, res3);
    }
}