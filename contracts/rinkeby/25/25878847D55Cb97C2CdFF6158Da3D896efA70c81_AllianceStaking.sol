//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Managable.sol";

contract AllianceStaking is Managable {
    struct Stake {
        address owner;
        uint256 amount;
    }

    // Storage
    mapping(uint256 => Stake[]) public stakings;
    mapping(address => uint256[]) public addressStakings;
    address stakingTokenAddress;

    // Events
    event AddedStake(address indexed _addr, uint256 indexed _id, uint256 _amount);
    event RemovedStake(address indexed _addr, uint256 indexed _id, uint256 _amount);
    event ChangedTokenAddress(address _addr);
    event ChangedAllianceStaking(uint256 indexed _id, uint256 _amount);

    constructor(
        address _tokenAddress
    ) {
        _setTokenAddress(_tokenAddress);
        _addManager(msg.sender);
    }

    function setTokenAddress(address _addr) external onlyManager {
        _setTokenAddress(_addr);
    }

    function stake(uint256 _id, uint256 _amount) external {
        _stake(msg.sender, _id, _amount);
    }

    function unstake(uint256 _id, uint256 _amount) external {
        _unstake(msg.sender, _id, _amount);
    }

    function allianceTotalStaking(uint256 _id) external view returns(uint256) {
        return _allianceTotalStaking(_id);
    }

    function addrStakings(address _addr) external view returns(uint256[] memory, uint256[] memory) {
        uint256[] memory _alliances = addressStakings[_addr];
        uint256[] memory _totals = new uint256[](_alliances.length);

        for(uint256 i = 0; i < _alliances.length; i++) {
            uint256 _amount;

            Stake[] memory _stakes = stakings[_alliances[i]];
            for(uint256 j = 0; j < _stakes.length; j++) {
                Stake memory _s = _stakes[i];
                if (_s.owner == _addr) {
                    _amount += _s.amount;
                    break;
                }
            }

            _totals[i] = _amount;
        }

        return (_alliances, _totals);
    }

    // Internal functions
    function _stake(address _sender, uint256 _id, uint256 _amount) internal {
        IERC20(stakingTokenAddress).transferFrom(_sender, address(this), _amount);

        (uint256 idx, bool found) = _findStakeIndex(_sender, _id);
        if (found) {
            Stake memory _s = stakings[_id][idx];
            _s.amount += _amount;
            stakings[_id][idx] = _s;
        } else {
            stakings[_id].push(Stake({
                owner: _sender,
                amount: _amount
            }));
        }

        _addAllianceToAddress(_sender, _id);

        uint256 total = _allianceTotalStaking(_id);
        emit AddedStake(_sender, _id, _amount);
        emit ChangedAllianceStaking(_id, total);        
    }

    function _unstake(address _sender, uint256 _id, uint256 _amount) internal {
        (uint256 idx, bool found) = _findStakeIndex(_sender, _id);
        if (found) {
            Stake memory _s = stakings[_id][idx];
            require(_s.amount >= _amount, "Not enough balance on staking");
            _s.amount -= _amount;
            stakings[_id][idx] = _s;
        } else {
            revert("Can't find staking for alliance");
        }

        IERC20(stakingTokenAddress).transfer(_sender, _amount);
        uint256 total = _allianceTotalStaking(_id);
        emit RemovedStake(_sender, _id, _amount);
        emit ChangedAllianceStaking(_id, total);        
    }

    function _findStakeIndex(address _sender, uint256 _id) internal view returns(uint256, bool){
        Stake[] memory _stakes = stakings[_id];

        // Updating stakings
        for(uint256 i = 0; i < _stakes.length; i++) {
            Stake memory _s = _stakes[i];
            if (_s.owner == _sender) {
                return (i, true);
            }
        }

        return (0, false);
    }

    function _addAllianceToAddress(address _addr, uint256 _id) internal {
        uint256[] memory _stakes = addressStakings[_addr];
        for (uint256 i = 0; i < _stakes.length; i++) {
            uint256 _s = _stakes[i];
            if (_s == _id) {
                return;
            }
        }

        addressStakings[_addr].push(_id);
    }

    function _setTokenAddress(address _addr) internal {
        stakingTokenAddress = _addr;
        emit ChangedTokenAddress(_addr);
    }

    function _allianceTotalStaking(uint256 _id) internal view returns(uint256 _amount) {
        Stake[] memory stakes = stakings[_id];

        for(uint256 i = 0; i < stakes.length; i++) {
            _amount += stakes[i].amount;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}