// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./interfaces/IRewardsDistribution.sol";

// Internal references
import "./interfaces/IERC20.sol";

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/RewardsDistribution.sol
contract RewardsDistribution is Owned, IRewardsDistribution {
    /**
     * @notice Authorised address able to call distributeRewards
     */
    address public authority;

    /**
     * @notice Address of the rewards token
     */
    address public rewardsToken;

    /**
     * @notice An array of addresses and amounts to send
     */
    DistributionData[] public distributions;

    /**
     * @dev _authority maybe the rewards distribution operator
     */
    constructor(
        address _owner,
        address _authority,
        address _rewardsToken
    ) Owned(_owner) {
        authority = _authority;
        rewardsToken = _rewardsToken;
    }

    // ========== EXTERNAL SETTERS ==========

    function setRewardToken(address _rewardsToken) external onlyOwner {
        rewardsToken = _rewardsToken;
    }

    /**
     * @notice Set the address of the contract authorised to call distributeRewards()
     * @param _authority Address of the authorised calling contract.
     */
    function setAuthority(address _authority) external onlyOwner {
        authority = _authority;
    }

    // ========== EXTERNAL FUNCTIONS ==========

    /**
     * @notice Adds a Rewards DistributionData struct to the distributions
     * array. Any entries here will be iterated and rewards distributed to
     * each address when tokens are sent to this contract and distributeRewards()
     * is called by the autority.
     * @param destination An address to send rewards tokens too
     * @param amount The amount of rewards tokens to send
     */
    function addRewardDistribution(address destination, uint amount) external onlyOwner returns (bool) {
        require(destination != address(0), "Cant add a zero address");
        require(amount != 0, "Cant add a zero amount");

        DistributionData memory rewardsDistribution = DistributionData(destination, amount);
        distributions.push(rewardsDistribution);

        emit RewardDistributionAdded(distributions.length - 1, destination, amount);
        return true;
    }

    /**
     * @notice Deletes a RewardDistribution from the distributions
     * so it will no longer be included in the call to distributeRewards()
     * @param index The index of the DistributionData to delete
     */
    function removeRewardDistribution(uint index) external onlyOwner {
        require(index <= distributions.length - 1, "index out of bounds");

        // shift distributions indexes across
        for (uint i = index; i < distributions.length - 1; i++) {
            distributions[i] = distributions[i + 1];
        }
        distributions.pop();

        // Since this function must shift all later entries down to fill the
        // gap from the one it removed, it could in principle consume an
        // unbounded amount of gas. However, the number of entries will
        // presumably always be very low.
    }

    /**
     * @notice Edits a RewardDistribution in the distributions array.
     * @param index The index of the DistributionData to edit
     * @param destination The destination address. Send the same address to keep or different address to change it.
     * @param amount The amount of tokens to edit. Send the same number to keep or change the amount of tokens to send.
     */
    function editRewardDistribution(
        uint index,
        address destination,
        uint amount
    ) external onlyOwner returns (bool) {
        require(index <= distributions.length - 1, "index out of bounds");

        distributions[index].destination = destination;
        distributions[index].amount = amount;

        return true;
    }

    function distributeRewards(uint amount) external override returns (bool) {
        require(amount > 0, "Nothing to distribute");
        require(msg.sender == authority, "Caller is not authorised");
        require(rewardsToken != address(0), "RewardsToken is not set");
        require(
            IERC20(rewardsToken).balanceOf(address(this)) >= amount,
            "RewardsDistribution contract does not have enough tokens to distribute"
        );

        // Iterate the array of distributions sending the configured amounts
        for (uint i = 0; i < distributions.length; i++) {
            if (distributions[i].destination != address(0) && distributions[i].amount != 0) {
                // Transfer the rewards token
                IERC20(rewardsToken).transfer(distributions[i].destination, distributions[i].amount);

                // If the contract implements RewardsDistributionRecipient.sol, inform it how much rewards tokens is received.
                bytes memory payload = abi.encodeWithSignature("notifyRewardAmount(uint256)", distributions[i].amount);

                // solhint-disable avoid-low-level-calls
                (bool success, ) = distributions[i].destination.call(payload);

                if (!success) {
                    // Note: we're ignoring the return value as it will fail for contracts that do not implement RewardsDistributionRecipient.sol
                }
            }
        }

        emit RewardsDistributed(amount);
        return true;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Retrieve the length of the distributions array
     */
    function distributionsLength() external view override returns (uint) {
        return distributions.length;
    }

    /* ========== Events ========== */

    event RewardDistributionAdded(uint index, address destination, uint amount);
    event RewardsDistributed(uint amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/Owned.sol
abstract contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/interfaces/IERC20.sol
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/interfaces/IRewardsDistribution.sol
interface IRewardsDistribution {
    // Structs
    struct DistributionData {
        address destination;
        uint amount;
    }

    // Views
    function distributionsLength() external view returns (uint);

    // Mutative Functions
    function distributeRewards(uint amount) external returns (bool);
}