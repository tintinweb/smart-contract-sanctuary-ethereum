// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IERC20.sol";

/**
 * @title CryptoAssetInsuranceFactory
 * @dev A contract for creating and managing crypto asset insurance contracts.
 */
contract CryptoAssetInsuranceFactory {
    address immutable owner;
    address immutable ethToUsd;
    address[] customers;
    mapping(address => address) public customerToContract;
    mapping(address => address) public contractToCustomer;
    mapping(uint8 => uint8) public plans;

    /**
     * @dev Constructor function.
     * @param _ethToUsd The address of the ETH to USD price oracle contract.
     */
    constructor(address _ethToUsd) payable {
        require(msg.value >= 0.1 ether, "Insufficient initial value");
        require(_ethToUsd != address(0), "Invalid oracle address");
        owner = msg.sender;
        plans[1] = 1;
        plans[2] = 5;
        plans[3] = 10;
        ethToUsd = _ethToUsd;
    }

    /**
     * @dev Returns the owner of the contract.
     * @return The address of the contract owner.
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    receive() external payable {}

    /**
     * @dev Withdraws the specified amount of funds from the contract to the owner's address.
     * @param amount The amount of funds to withdraw.
     */
    function withdraw(uint256 amount) public payable {
        require(msg.sender == owner, "Only contract owner can call this function");
        require(address(this).balance >= amount, "Insufficient contract balance");
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Failed to send funds");
    }

    /**
     * @dev Returns an array of customer addresses.
     * @return An array of customer addresses.
     */
    function getCustomers() public view returns (address[] memory) {
        return customers;
    }

    /**
     * @dev Returns the insurance contract address associated with the given customer address.
     * @param customerAddress The customer address.
     * @return The insurance contract address.
     */
    function getCustomerToContract(address customerAddress) public view returns (address) {
        return customerToContract[customerAddress];
    }

    /**
     * @dev Returns the balance of the specified token for the given account address.
     * @param tokenAddress The address of the token.
     * @param accountAddress The account address.
     * @return The token balance.
     */
    function getTokenBalance(address tokenAddress, address accountAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(accountAddress);
    }

    /**
     * @dev Returns the latest feed value of the specified asset from the given oracle address.
     * @param _oracleAddress The address of the price oracle contract.
     * @return The latest feed value.
     */
    function getFeedValueOfAsset(address _oracleAddress) public view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(_oracleAddress);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt */
            ,
            /*uint timeStamp */
            ,
            /*uint80 answeredInRound */
        ) = priceConsumer.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev Returns the conversion rate from USD to Wei.
     * @return The conversion rate.
     */
    function getUsdToWei() public view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(ethToUsd);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt */
            ,
            /*uint timeStamp */
            ,
            /*uint80 answeredInRound */
        ) = priceConsumer.latestRoundData();
        return uint256((10 ** 26) / price);
    }

    /**
     * @dev Calculates the deposit amount required for the insurance.
     * @param _tokens The number of tokens.
     * @param _plan The insurance plan (1, 2, or 3).
     * @param _priceAtInsurance The price of the asset at the time of insurance.
     * @param _decimals The number of decimals for the asset.
     * @param _timePeriod The insurance time period.
     * @return The deposit amount payable.
     */
    function calculateDepositMoney(
        uint256 _tokens,
        uint256 _plan,
        uint256 _priceAtInsurance,
        uint256 _decimals,
        uint256 _timePeriod
    ) public view returns (uint256) {
        uint256 conversionRate = getUsdToWei();
        uint256 pricePayable =
            (_priceAtInsurance * _tokens * _plan * _timePeriod * conversionRate) / (10 ** (_decimals * 2 + 2));
        return pricePayable;
    }

    /**
     * @dev Creates a new insurance contract for the specified asset.
     * @param plan The insurance plan (1, 2, or 3).
     * @param assetAddress The address of the asset token.
     * @param timePeriod The insurance time period.
     * @param oracleAddress The address of the price oracle contract for the asset.
     * @param decimals The number of decimals for the asset.
     * @param tokensInsured The number of tokens to be insured.
     */
    function getInsurance(
        uint8 plan,
        address assetAddress,
        uint256 timePeriod,
        address oracleAddress,
        uint256 decimals,
        uint256 tokensInsured
    ) public payable {
        require(customerToContract[msg.sender] == address(0), "Insurance contract already exists for the customer");
        uint256 totalTokens = getTokenBalance(assetAddress, msg.sender);
        require(tokensInsured > 0 && tokensInsured <= totalTokens, "Invalid token amount");
        uint8 _plan = plans[plan];
        require(_plan != 0, "Invalid plan");
        uint256 priceAtInsurance = getFeedValueOfAsset(oracleAddress);
        uint256 pricePayable = calculateDepositMoney(tokensInsured, _plan, priceAtInsurance, decimals, timePeriod);
        require(msg.value == (pricePayable), "Incorrect insurance amount sent");
        address insuranceContract = address(
            new AssetWalletInsurance(
                msg.sender,
                assetAddress,
                tokensInsured,
                _plan,
                timePeriod,
                (address(this)),
                oracleAddress,
                priceAtInsurance,
                decimals
            )
        );
        customerToContract[msg.sender] = insuranceContract;
        contractToCustomer[insuranceContract] = msg.sender;
        customers.push(msg.sender);
    }

    /**
     * @dev Allows an insurance contract to claim the insurance amount.
     */
    function claimInsurance() public payable {
        require(contractToCustomer[msg.sender] != address(0), "Only insurance contracts can call this function");

        AssetWalletInsurance instance = AssetWalletInsurance(payable(msg.sender));
        uint256 _claimAmount = instance.getClaimAmount();
        uint256 _decimals = instance.decimals();
        require(_claimAmount != 0, "Claim amount should not be 0");
        uint256 conversionRate = getUsdToWei();
        uint256 amountSent = (conversionRate * _claimAmount) / 10 ** _decimals;
        require(amountSent < address(this).balance, "Not enough funds in contract");
        (bool sent,) = msg.sender.call{value: amountSent}("");
        require(sent, "Transaction was not successful");
    }
}

/**
 * @title AssetWalletInsurance
 * @dev Contract representing the insurance for an asset wallet.
 */
contract AssetWalletInsurance {
    address public immutable owner;
    address public immutable assetAddress;
    uint256 public immutable tokensInsured;
    uint256 public immutable plan;
    uint256 public immutable timePeriod;
    uint256 public claimAmount;
    address public immutable factoryContract;
    address public immutable oracleAddress;
    uint256 public priceAtInsurance;
    uint256 public decimals;
    bool public claimed;

    /**
     * @dev Modifier to check if the caller is the owner of the insurance contract.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /**
     * @dev Initializes the insurance contract.
     * @param _owner The address of the wallet owner.
     * @param _assetAddress The address of the asset token.
     * @param _tokensInsured The number of tokens insured.
     * @param _plan The insurance plan (1, 2, or 3).
     * @param _timePeriod The insurance time period.
     * @param _factoryContract The address of the insurance factory contract.
     * @param _oracleAddress The address of the price oracle contract for the asset.
     * @param _priceAtInsurance The price of the asset at the time of insurance.
     * @param _decimals The number of decimals for the asset.
     */
    constructor(
        address _owner,
        address _assetAddress,
        uint256 _tokensInsured,
        uint256 _plan,
        uint256 _timePeriod,
        address _factoryContract,
        address _oracleAddress,
        uint256 _priceAtInsurance,
        uint256 _decimals
    ) {
        owner = _owner;
        assetAddress = _assetAddress;
        tokensInsured = _tokensInsured;
        plan = _plan;
        timePeriod = block.timestamp + _timePeriod * 2629743; // validity in minutes (assuming 30 days per month)
        factoryContract = _factoryContract;
        oracleAddress = _oracleAddress;
        priceAtInsurance = _priceAtInsurance;
        decimals = _decimals;
    }

    receive() external payable {}

    function withdrawClaim() public payable onlyOwner {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Failed Transaction");
    }

    function claim() public onlyOwner {
        require(!claimed, "Already Claimed Reward");
        verifyInsurance();
        // console.log("Claim amount is //////////////");
        // console.log(claimAmount);
        claimed = true;
        (bool success,) = factoryContract.call(abi.encodeWithSignature("claimInsurance()"));
        require(success, "Transaction Failed in claim");
    }

    function getClaimAmount() public view returns (uint256) {
        return claimAmount;
    }

    function isClaimed() public view returns (bool) {
        return claimed;
    }

    /**
     * @dev Verifies the insurance and calculates the claim amount.
     */
    function verifyInsurance() internal onlyOwner {
        require(timePeriod > block.timestamp, "Oops, your insurance has expired");
        require(!claimed, "Already claimed");
        uint256 currentPrice = getFeedValueOfAsset(oracleAddress);
        require(currentPrice < priceAtInsurance, "There is no change in asset price");
        uint256 totalAmount = getInsuranceAmount(currentPrice);
        require(totalAmount > 0, "No claimable amount");
        uint256 maximumClaimableAmount = (totalAmount * plan) / 10;
        if (totalAmount < maximumClaimableAmount) {
            claimAmount = totalAmount;
        } else {
            claimAmount = maximumClaimableAmount;
        }
    }

    /**
     * @dev Retrieves the token balance of an account for a given token address.
     * @param tokenAddress The address of the token.
     * @param accountAddress The address of the account.
     * @return The token balance.
     */
    function getTokenBalance(address tokenAddress, address accountAddress) internal view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(accountAddress);
    }

    /**
     * @dev Retrieves the latest feed value of an asset from the specified oracle address.
     * @param _oracleAddress The address of the price oracle contract.
     * @return The latest feed value.
     */
    function getFeedValueOfAsset(address _oracleAddress) internal view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(_oracleAddress);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt */
            ,
            /*uint timeStamp */
            ,
            /*uint80 answeredInRound */
        ) = priceConsumer.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev Calculates the insurance amount based on the current asset price.
     * @param _currentPrice The current price of the asset.
     * @return The total insurance amount.
     */
    function getInsuranceAmount(uint256 _currentPrice) public view returns (uint256) {
        uint256 tokensHold = getTokenBalance(assetAddress, owner);
        uint256 claimableTokens;
        if (tokensHold < tokensInsured) {
            claimableTokens = tokensHold;
        } else {
            claimableTokens = tokensInsured;
        }
        return (((priceAtInsurance - _currentPrice) * claimableTokens) / 10 ** decimals);
    }

    /**
     * @dev Allows the owner of the insurance contract to claim the insurance amount.
     */
    function claimInsurance() external onlyOwner {
        verifyInsurance();
        require(claimAmount > 0, "Claim amount should not be 0");
        (bool sent,) = msg.sender.call{value: claimAmount}("");
        require(sent, "Transaction was not successful");
        claimed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}