//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import "hardhat/console.sol";

interface IReefToken {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
}

contract ReefCardTopUpReceiver {
    address public immutable reefToken;
    address public owner;
    address public filler;
    uint256 public maxTopUpValue;
    mapping(bytes32 => bool) public filledReefTx;
    mapping(address => bool) public isWhitelisted;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event FillerChanged(address indexed oldFiller, address indexed newFiller);
    event MaxTopUpValueChanged(uint256 indexed oldValue, uint256 indexed newValue);
    event WhitelistChanged(address[] addressList, bool added);
    event TopUpFilled(
        bytes32 indexed reefTxHash,
        address indexed toAddress,
        uint256 amount,
        uint256 reefBalance
    );

    error CallerIsNotOwner();
    error CallerIsNotFiller();
    error TxAlreadyFilled();
    error ValueSentTooHigh();
    error NotValidAddress();

    modifier onlyOwner() {
        if (owner != msg.sender) revert CallerIsNotOwner();
        _;
    }

    constructor(
        address _owner,
        address _filler,
        address _reefToken,
        uint256 _maxTopUpValue
    ) {
        owner = _owner;
        filler = _filler;
        reefToken = _reefToken;
        maxTopUpValue = _maxTopUpValue;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnerChanged(oldOwner, newOwner);
    }

    function setFiller(address newFiller) external onlyOwner {
        address oldFiller = filler;
        filler = newFiller;
        emit FillerChanged(oldFiller, newFiller);
    }

    function setMaxTopUpValue(uint256 newMaxTopUpValue) external onlyOwner {
        uint256 oldMaxTopUpValue = maxTopUpValue;
        maxTopUpValue = newMaxTopUpValue;
        emit MaxTopUpValueChanged(oldMaxTopUpValue, newMaxTopUpValue);
    }

    function addToWhitelist(address[] calldata addressList) external onlyOwner {
        uint256 totalAddresses = addressList.length;
        for (uint256 i; i < totalAddresses; ++i) {
            isWhitelisted[addressList[i]] = true;
        }

        emit WhitelistChanged(addressList, true);
    }

    function removeFromWhitelist(address[] calldata addressList) external onlyOwner {
        uint256 totalAddresses = addressList.length;
        for (uint256 i; i < totalAddresses; ++i) {
            isWhitelisted[addressList[i]] = false;
        }

        emit WhitelistChanged(addressList, false);
    }

    function fillTopUp(
        bytes32 reefTxHash,
        address payable toAddress,
        uint256 amount
    ) external {
        if (filler != msg.sender) revert CallerIsNotFiller();
        if (filledReefTx[reefTxHash]) revert TxAlreadyFilled();
        if (amount > maxTopUpValue) revert ValueSentTooHigh();
        if (!isWhitelisted[toAddress]) revert NotValidAddress();

        filledReefTx[reefTxHash] = true;
        IReefToken(reefToken).transfer(toAddress, amount);

        emit TopUpFilled(
            reefTxHash,
            toAddress,
            amount,
            IReefToken(reefToken).balanceOf(address(this))
        );
    }

    function fillTopUp_noWhitelist(
        bytes32 reefTxHash,
        address payable toAddress,
        uint256 amount
    ) external {
        if (filler != msg.sender) revert CallerIsNotFiller();
        if (filledReefTx[reefTxHash]) revert TxAlreadyFilled();
        if (amount > maxTopUpValue) revert ValueSentTooHigh();

        filledReefTx[reefTxHash] = true;
        IReefToken(reefToken).transfer(toAddress, amount);

        emit TopUpFilled(
            reefTxHash,
            toAddress,
            amount,
            IReefToken(reefToken).balanceOf(address(this))
        );
    }

    function fillTopUp_transferFrom(
        bytes32 reefTxHash,
        address payable toAddress,
        uint256 amount
    ) external {
        if (filler != msg.sender) revert CallerIsNotFiller();
        if (filledReefTx[reefTxHash]) revert TxAlreadyFilled();
        if (amount > maxTopUpValue) revert ValueSentTooHigh();
        if (!isWhitelisted[toAddress]) revert NotValidAddress();

        filledReefTx[reefTxHash] = true;
        IReefToken(reefToken).transferFrom(owner, toAddress, amount);

        emit TopUpFilled(
            reefTxHash,
            toAddress,
            amount,
            IReefToken(reefToken).allowance(owner, address(this))
        );
    }
}