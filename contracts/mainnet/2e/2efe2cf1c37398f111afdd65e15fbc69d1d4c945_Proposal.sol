/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function modifyParameters(bytes32, uint256) public virtual;
    function modifyParameters(bytes32, address) public virtual;
    function removeAuthority(address) public virtual;
    function removeAuthorization(address) public virtual;
}

contract Proposal {
    function execute(bool) public {
        address pidCalculator     = 0xddA334de7A9C57A641616492175ca203Ba8Cf981; // new
        address rateSetter        = 0x7Acfc14dBF2decD1c9213Db32AE7784626daEb48;
        address deployer          = 0x3E0139cE3533a42A7D342841aEE69aB2BfEE1d51;

        Setter(rateSetter).modifyParameters("pidCalculator", pidCalculator);
        Setter(pidCalculator).modifyParameters("seedProposer", rateSetter);
        Setter(pidCalculator).removeAuthority(deployer);
    }
}