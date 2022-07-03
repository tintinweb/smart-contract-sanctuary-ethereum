/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

// error Palabra__NotOwner();
error Palabra__NotEnoughMoney();

contract Palabra {
    string private s_palabra;
    address private immutable i_owner;
    uint256 private constant MINIMUM_ETH = 0.1 * 1e18;

    // modifier onlyOwner() {
    //     if (msg.sender != i_owner) {
    //         revert Palabra__NotOwner();
    //     }
    //     _;
    // }

    modifier requiredFee() {
        if (msg.value < MINIMUM_ETH) {
            revert Palabra__NotEnoughMoney();
        }
        _;
    }

    constructor(string memory palabra) {
        s_palabra = palabra;
        i_owner = msg.sender;
    }

    receive() external payable {
        setPalabraDef();
    }

    fallback() external payable {
        setPalabraDef();
    }

    function getPalabra() public view returns (string memory) {
        return s_palabra;
    }

    // https://ethereum.stackexchange.com/questions/74442/when-should-i-use-calldata-and-when-should-i-use-memory
    // calldata es mas barato que memory
    function setPalabra(string calldata palabra) public payable {
        if (msg.sender != i_owner) {
            if (msg.value < MINIMUM_ETH) {
                revert Palabra__NotEnoughMoney();
            }
        }

        s_palabra = palabra;
    }

    function setPalabraDef() public payable requiredFee {
        s_palabra = "Gracias!";
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}