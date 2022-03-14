/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity >=0.8.4;

/* @title Empty implementation of CrocSwap interface */
contract CrocShell {

    function swap (address base, address quote,
                   uint256 poolIdx, bool isBuy, bool inBaseQty, uint128 qty, uint16 tip,
                   uint128 limitPrice, uint128 minOut,
                   uint8 settleFlags) public payable returns (int128) { }

    function protocolCmd (uint16 callpath, bytes calldata cmd, bool sudo)
        public payable returns (bytes memory) { }

    function userCmd (uint16 callpath, bytes calldata cmd)
        public payable returns (bytes memory) { }

    function userCmdRelayer (uint16 callpath, bytes calldata cmd,
                             bytes calldata conds, bytes calldata relayerTip,
                             bytes calldata signature)
        public payable returns (bytes memory output) { }

    function userCmdRouter (uint16 callpath, bytes calldata cmd, address client,
                            uint256 salt)
        public payable returns (bytes memory) { }

    function readSlot (uint256 slot) public view returns (uint256) { }
}