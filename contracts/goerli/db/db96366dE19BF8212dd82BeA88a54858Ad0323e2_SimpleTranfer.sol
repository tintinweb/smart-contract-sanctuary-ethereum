/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract SimpleTranfer {


    constructor() {
        address a = msg.sender;
        balances[a] = 10000;
    }
    event Tran(address s, address t, uint256 a);

    mapping(address=>uint256) public balances ;

    function transfer(address a, uint256 v) public {
        address fa = msg.sender;
        uint256 s = balances[fa];
        require(s>=v, "no enough funds");
        uint256 tobanalce = balances[a];
        balances[fa] = s-v;
        balances[a] = tobanalce + v;
        emit Tran(fa, a, v);
    }

    function airdrop( address a) public {
        uint256 tobanalce = balances[a];
        balances[a] = tobanalce +1000;
    
    }

    function getAmount(address a) public view returns (uint256) {
        uint256 tobanalce = balances[a];
        return tobanalce;
    }
}