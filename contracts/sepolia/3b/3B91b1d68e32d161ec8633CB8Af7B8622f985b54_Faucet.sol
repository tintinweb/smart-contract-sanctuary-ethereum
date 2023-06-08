pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "./interfaces/IAgency.sol";

interface token {
    function mint(address to, uint amount) external returns (bool);
}

contract Faucet {
    token public token0;
    token public token1;
    token public token2;
    IAgency public agency;
    uint constant amount0 = 10000e18; //DYSN
    uint constant amount1 = 10000e6; //USDC
    uint constant amount2 = 1e8; //WBTC
    address public signer;

    mapping(address => bool) public tokenClaimed;
    mapping(address => bool) public agentClaimed;

    function set(address _token0, address _token1, address _token2, address _agency, address _signer) external {
        token0 = token(_token0);
        token1 = token(_token1);
        token2 = token(_token2);
        agency = IAgency(_agency);
        signer = _signer;
    }

    function claimToken(uint8 v, bytes32 r, bytes32 s) external {
        string memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 digest = keccak256(abi.encodePacked(msg.sender, "claimToken"));
        require(ecrecover(keccak256(abi.encodePacked(prefix, digest)), v, r, s) == signer, "invalid sig");
        require(!tokenClaimed[msg.sender]);
        tokenClaimed[msg.sender] = true;
        token0.mint(msg.sender, amount0);
        token1.mint(msg.sender, amount1);
        token2.mint(msg.sender, amount2);
    }

    function claimAgent(uint8 v, bytes32 r, bytes32 s) external {
        string memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 digest = keccak256(abi.encodePacked(msg.sender, "claimAgent"));
        require(ecrecover(keccak256(abi.encodePacked(prefix, digest)), v, r, s) == signer, "invalid sig");
        require(!agentClaimed[msg.sender]);
        agentClaimed[msg.sender] = true;
        agency.adminAdd(msg.sender);
    }

}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IAgency {
    function whois(address agent) external view returns (uint);
    function userInfo(address agent) external view returns (address ref, uint gen);
    function transfer(address from, address to, uint id) external returns (bool);
    function totalSupply() external view returns (uint);
    function getAgent(uint id) external view returns (address, uint, uint, uint, uint[] memory);
    function adminAdd(address newUser) external returns (uint id);
}