/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

pragma solidity ^0.8.0;



contract FlashArbitrageurBot {

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public owner;

    event Msg(address token, uint256 amount, address[] pairs);
    event Msg0(uint index);
    event Msg1(string str);
    event Msg2(bytes data);
    
    
    constructor() {
        owner = msg.sender;
    }

    receive() payable external {}

    

    function arbitrage(string[] memory strs) external{
        uint index = parseInt(strs[0], 0);
        bytes memory data = bytes(strs[index]);
        string memory str = abi.decode(data,(string));
        // bytes memory d = bytes(str1);

        // (address token, uint256 amount, address[] memory pairs)  = abi.decode(d, (address, uint, address[]));

        emit Msg0(index);
        emit Msg1(str);
        // emit Msg(token, amount, pairs);

        // (address token, uint256 amount, address[] memory pairs)  = abi.decode(data, (address, uint, address[]));
        //  _arbitrage(token, amount, pairs);
    }

    function _arbitrage(address token, uint256 amount, address[] memory pairs) internal {

        uint count = pairs.length;       
        for(uint i = 0; i < count; i++){

            address pair = pairs[i];
            // emit Msg(token, amount, pair);
        }

    }


    

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

}