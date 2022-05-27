// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/**
 * @title Contract that allows users to managed their collateral funds.
 * @dev For the moment, the only collateral accepted is the USDC.
 * @author The Everest team: https://github.com/Everest-Option-Exchange-Team.
 */
contract CollateralFundV1 {
    // Fund parameters.
    mapping(address => uint256) public addressToCollateralAmount;
    mapping(address => bool) public addressToFunderStatus; // It returns false if the user is not in the funders list.
    address[] public funders;

    // USDC token parameters.
    address public usdcAddress;
    IERC20 public usdcContract;

    // Access-control parameters.
    address public owner;
    address public hubAddress;

    // Modifiers
    modifier onlyOwner() {
        require (msg.sender == owner, "Only the owner can call this method");
        _;
    }

    // Events
    event Deposit(address indexed addr, uint256 amount, uint256 updatedUserCollateralAmount);
    event Withdraw(address indexed addr, uint256 amount, uint256 updatedUserCollateralAmount);
    event CollateralAmountUpdated(address indexed addr, uint256 previousAmount, uint256 newAmount);
    event NewFunder(address addr);
    event RemoveFunder(address addr);
    event USDCTokenAddressUpdated(address oldAddress, address newAddress);
    event HubAddressUpdated(address oldAddress, address newAddress);

    /**
     * @notice Initialise the contract.
     * @param _usdcAddress the address of the USDC token contract.
     * @param _hubAddress the address of the hub.
     */
    //slither-disable-next-line naming-convention
    constructor(address _usdcAddress, address _hubAddress) {
        owner = msg.sender;
        usdcAddress = _usdcAddress;
        usdcContract = IERC20(_usdcAddress);
        hubAddress = _hubAddress;
    }

    /**************************************** Fund / Withdraw ****************************************/

    /**
     * @notice Deposit collateral to the fund.
     * @param _amount the amount of USDC token send to the fund.
     */
    //slither-disable-next-line naming-conventions
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount should be greator than zero");

        // Send the USDC from the user's wallet to the fund and update the user collateral amount.
        usdcContract.transferFrom(msg.sender, address(this), _amount);
        addressToCollateralAmount[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount, addressToCollateralAmount[msg.sender]);

        // Add the sender to the funders list if he's not already in the list.
        if (!addressToFunderStatus[msg.sender]) {
            addressToFunderStatus[msg.sender] = true;
            funders.push(msg.sender);
            emit NewFunder(msg.sender);
        }
    }

    /**
     * @notice Withdraw collateral from the fund.
     * @param _amount the amount to withdraw from the fund.
     */
    //slither-disable-next-line naming-convention
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount should be greator than zero");
        require(addressToFunderStatus[msg.sender], "The user has not deposited any collateral to the fund");
        require(_amount <= addressToCollateralAmount[msg.sender], "The user cannot withdraw more than what he deposited");

        // Send the USDC from the fund to the user's wallet and update the user collateral amount.
        usdcContract.transfer(msg.sender, _amount);
        addressToCollateralAmount[msg.sender] -= _amount;
        emit Deposit(msg.sender, _amount, addressToCollateralAmount[msg.sender]);

        // Remove the burner from the funders list if his balance is equal to 0.
        if (addressToCollateralAmount[msg.sender] == 0) {
            addressToFunderStatus[msg.sender] = false;
            for (uint256 i = 0; i < funders.length; i++) {
                if (funders[i] == msg.sender) {
                    delete funders[i];
                    emit RemoveFunder(msg.sender);
                }
            }
        }
    }

    /**************************************** Getters ****************************************/

    /**
     * @notice Get the amount of collateral deposited by a user.
     * @param _userAddress the address of the user.
     * @return _ the amount deposited by the user.
     */
    //slither-disable-next-line naming-convention
    function getUserCollateralAmount(address _userAddress) external view returns (uint256) {
        return addressToCollateralAmount[_userAddress];
    }

    /**
     * @notice Get the list of users who have deposited collateral to the fund.
     * @return _ the list of funders.
     */
    function getFunders() external view returns (address[] memory) {
        return funders;
    }

    /**************************************** Setters ****************************************/

    /**
     * @notice Update the amount of collateral deposited by a user.
     * @param _userAddress the address of the user.
     * @param _newCollateralAmount the new amount of collateral of the user.
     * @dev This method is used by the Hub to liquidate users positions.
     */
    //slither-disable-next-line naming-convention
    function setUserCollateralAmount(address _userAddress, uint256 _newCollateralAmount) external {
        require(msg.sender == hubAddress, "Only the hub can call this method");
        require(_userAddress != address(0), "The address parameter cannot be null");

        emit CollateralAmountUpdated(_userAddress, addressToCollateralAmount[_userAddress], _newCollateralAmount);
        addressToCollateralAmount[_userAddress] = _newCollateralAmount;
    }

    /**
     * @notice Update the USDC token address.
     * @param _usdcAddress the new USDC token address.
     */
     //slither-disable-next-line naming-convention
    function setUsdcAddress(address _usdcAddress) external onlyOwner {
        require(_usdcAddress != address(0), "The address parameter cannot be null");
        emit HubAddressUpdated(usdcAddress, _usdcAddress);
        usdcAddress = _usdcAddress;
        usdcContract = IERC20(_usdcAddress);
    }

    /**
     * @notice Update the hub address.
     * @param _hubAddress the new hub address.
     */
     //slither-disable-next-line naming-convention
    function setHubAddress(address _hubAddress) external onlyOwner {
        require(_hubAddress != address(0), "The address parameter cannot be null");
        emit USDCTokenAddressUpdated(hubAddress, _hubAddress);
        hubAddress = _hubAddress;
    }
}

// Interfaces

interface IERC20 {
    function transfer(address receiverAddress, uint amount) external returns (bool);
    function transferFrom(address senderAddress, address receiverAddress, uint amount) external returns (bool);
    function balanceOf(address userAddress) external view returns (uint);
}