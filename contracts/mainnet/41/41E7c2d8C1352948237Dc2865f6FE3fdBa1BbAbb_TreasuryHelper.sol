// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";
import "./libs/Ownable.sol";
import "./interfaces/ITreasury.sol";

contract TreasuryHelper is Ownable {

    ITreasury private treasury;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private psi;

    constructor (address _treasury, address _psi) {
        require(_treasury != address(0));
        psi = _psi;
        treasury = ITreasury(_treasury);
    }

    function setPsiAddress(address _psiAddress) external onlyManager() {
        psi = _psiAddress;
    }

    function setTreasury(address _treasury) external onlyManager() {
        require(_treasury != address(0));
        treasury = ITreasury(_treasury);
    }

    function depositTreasury(uint _amount, uint _profit) public onlyManager() {
        uint256 balance = IERC20(DAI).balanceOf(address(this));
        require(_amount <= balance);

        IERC20(DAI).approve(address(treasury), _amount);
        treasury.deposit(_amount, DAI, _profit);
    }

    function depositTreasury() external {
        require(msg.sender == psi);
        uint balance = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).approve(address(treasury), balance);
        IERC20(DAI).approve(address(ROUTER), balance);
        treasury.deposit(balance, DAI, balance);
    }

    function withdraw() external onlyManager {
        uint256 balance = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).transfer(msg.sender, balance);
    }

    function withdrawEth() public payable onlyManager {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IStaking {

    function stake(uint _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../interfaces/IOwnable.sol";

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyManager() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

pragma solidity 0.7.5;

interface ITreasury {

    function deposit(uint _amount, address _token, uint _profit) external returns (uint send_);

    function mintRewards(address _recipient, uint _amount) external;

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {

    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;

}