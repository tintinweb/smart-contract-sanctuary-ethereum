pragma solidity >=0.8.10;

import "./ERC20.sol";
import "./Owned.sol";

contract Papaya is ERC20, Owned {

    mapping(address => bool) private authorizedStakingContracts;

    constructor() ERC20("PAPAYA", "PAPAYA", 18) Owned(msg.sender) {}

    function ownerMint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function stakerMint(address account, uint256 amount) external {
        require(
            authorizedStakingContracts[msg.sender],
            "Request only valid from staking contract"
        );
        _mint(account, amount);
    }

    function flipStakingContract(address staker) external onlyOwner {
        authorizedStakingContracts[staker] = !authorizedStakingContracts[staker];
    }

    function burn(address user, uint256 amount) external {
        require(user == msg.sender, "Not your tokens");
        _burn(user, amount);
    }
}