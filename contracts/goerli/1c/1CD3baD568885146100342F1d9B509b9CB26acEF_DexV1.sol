// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//This is an exercise to put into practice a Dex based on Uniswap's V1 protocol,
//as a pair that exchanges native ETH with DEX tokens, an ERC20.

//The exchange price is regulated by an automatic market making formula.

//Exchanges are done both ways:

//ETH to DEX tokens
//DEX Tokens to ETH requires the Dex to be approved to take ERC20 tokens from wallet.

//The liquidity provided to this contract by the users is represented by another ERC20 token that is minted upon liquidity deposits.
//Users pay a 0.3% fee for every exchange, and this value is captured in the liquidity pool.
//Liquidity providers can burn their LP tokens to withdraw their liquidity adding the proportional part of the 0.3% of every transaction
//that was perfomed while they lended liquidity.

/// @title AMM Decentralized Exchange for DEX / ETH pair
/// @author 0x4152
/// @notice This contract is meant to showcase how a AMM DEX with LP tokens works, it is for educational purposes.
contract DexV1 {
    IERC20 token;

    uint256 public totalLiquidity;
    address public LPTokenAddress;
    bool internal LPTokenAddressIsSet = false;
    bool internal isInitialized = false;
    address public LPTokenAddressSetter;

    event Initialized(
        uint256 indexed ETHAmount,
        uint256 indexed TokenAmount,
        address indexed initializer
    );
    event Deposited(
        address indexed user,
        uint256 indexed ethDeposited,
        uint256 indexed tokensDeposited
    );
    event Withdrawed(
        address indexed user,
        uint256 indexed ethWithdrawed,
        uint256 indexed tokensWithdrawed
    );
    event EthToTokenExchanged(
        address indexed user,
        uint256 indexed ethSent,
        uint256 indexed tokensBought
    );
    event TokenToEthExchanged(
        address indexed user,
        uint256 indexed tokensSent,
        uint256 indexed ethBought
    );
    event LPTokenAddressSet(
        address indexed LPTokenAddress,
        address indexed user,
        uint256 indexed time
    );

    /// @notice Checks in several functions that the contract has been initialized.
    modifier initialized() {
        require(isInitialized == true, "liquidity pool has not been initialized yet");
        _;
    }

    constructor(address yeahTokenAddress) public {
        token = IERC20(yeahTokenAddress);
        LPTokenAddressSetter = msg.sender;
    }

    /// @notice Function called by the deployer of the contract that sets the address for the LP tokens. It should be set only once.
    /// @dev The LP token address represents a huge weak point, the LPTokenAddressSetter address is a fully trusted account.
    /// @param _LPTokenAddress The address of the ERC20 LP token, that represents the liquidity providers stake in the pool.
    function setLPTokenAddress(address _LPTokenAddress) public {
        require(!LPTokenAddressIsSet, "LP token address has already been set");
        require(msg.sender == LPTokenAddressSetter, "you are not the address setter");
        LPTokenAddress = _LPTokenAddress;
        LPTokenAddressIsSet = true;
        emit LPTokenAddressSet(_LPTokenAddress, msg.sender, block.timestamp);
    }

    /// @notice Initializes the pool with reserves of DEX token and ETH
    /// @dev The initial ratio deposited will hugely impact exchange price of assets
    /// @param tokens The amount of DEX tokens the user wants to deposit in the liquidity pool relative to the msg.value
    /// @return The total amount of liquidity, that's represented by LP tokens.
    function init(uint256 tokens) public payable returns (uint256) {
        require(LPTokenAddressIsSet == true, "LP token Address has not been set yet");
        require(totalLiquidity == 0, "dex has already been initialized");
        // if someone force sends eth before calling the init function, the liquidity provided will be captured by
        //the user that calls init.
        totalLiquidity = address(this).balance;

        require(token.transferFrom(msg.sender, address(this), tokens));

        //mint the LP tokens to the address that initializes the pool
        (bool success, ) = LPTokenAddress.call(
            abi.encodeWithSignature("mintTokensTo(address,uint256)", msg.sender, totalLiquidity)
        );
        require(success, "mint tx failed");
        isInitialized = true;
        emit Initialized(totalLiquidity, tokens, msg.sender);
        return totalLiquidity;
    }

    /// @notice Exchanges ETH for DEX tokens.
    /// @dev The amount of tokens returned is calculated by the price function.
    /// @return The amount of tokens that have been bought.
    function ethToToken() public payable initialized returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokensBought = price(msg.value, address(this).balance - msg.value, tokenReserve);
        require(token.transfer(msg.sender, tokensBought), "failed to transfer ETH");
        emit EthToTokenExchanged(msg.sender, msg.value, tokensBought);
        return tokensBought;
    }

    /// @notice Exchanges DEX tokens for ETH
    /// @dev This function will need approval from user to this contract to transfer their DEX tokens.
    /// @param tokens The amount of DEX tokens the user wants to exchange.
    /// @return The amount of ETH the user gets in return for exchaning tokens.
    function tokenToEth(uint256 tokens) public payable initialized returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethBought = price(tokens, tokenReserve, address(this).balance);
        require(token.transferFrom(msg.sender, address(this), tokens), "failed to transfer tokens");
        (bool sent, ) = msg.sender.call{value: ethBought}("");
        require(sent, "failed to send ETH");
        emit TokenToEthExchanged(msg.sender, tokens, ethBought);
        return ethBought;
    }

    /// @notice Deposits reserve assets into the pool and gives user LP tokens in exchange, which represent the user's share in the pool.
    /// @dev The amount of tokens introduced into the pool will depend on how much ETH is sent and the pool's asset ratio, the user will need to approve the token amount.
    /// @return The LP token amount minted to the user.
    function deposit() public payable initialized returns (uint256) {
        uint256 eth_reserve = address(this).balance - msg.value;
        uint256 token_reserve = token.balanceOf(address(this));
        //token amount example with a pool with reserves of 4 eth and 8000 Dai
        // we send 1 eth, 1 * 8000 / 4 = 2000, therefore it will input the balance of 1 2000
        uint256 token_amount = ((msg.value * token_reserve) / eth_reserve) + 1;

        //((eth sent * total liquidity shares ) / eth reserves ) + 1
        // the previous formula with 18 decimals makes it so that the LP tokens minted to the user is
        //equal to the eth sent, since the total liquidity shares in V1 is always going to be equal to the eth reserves.
        uint256 liquidity_minted = (msg.value * totalLiquidity) / eth_reserve;

        //liquidity tokens added to user balance
        //update total liquidity for future liquidity operations
        totalLiquidity = totalLiquidity + liquidity_minted;
        //call transferFrom with the approved tokens to this contract to finish adding liquidity
        require(token.transferFrom(msg.sender, address(this), token_amount));
        (bool success, ) = LPTokenAddress.call(
            abi.encodeWithSignature("mintTokensTo(address,uint256)", msg.sender, liquidity_minted)
        );
        require(success, "mint tx failed");
        emit Deposited(msg.sender, msg.value, token_amount);
        return liquidity_minted;

        //on V2 the process is transferFunction agnostic, there is no approval, instead, the tokens must be sent to the contract,
        //the contract itself will keep track of the token balance after each interaction, and will calculate how many tokens you have sent,
        //based on the difference between the balanceOf its own address in the ERC20 contract, with its own balance data structure.
    }

    /// @notice Burns LP tokens from the user and transfers the underlying assets the tokens represent from the pool back to the user.
    /// @dev The minting and burning of the LP tokens can only be performed by this contract.
    /// @return The ETH amount and the DEX token amount returned for withdrawing the liquidity.
    function withdraw(uint256 amount) public initialized returns (uint256, uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        //on the same pool mentioned before, with 5 eth and 10000 DAI the user inputs 1 as amount
        //1 * 5 / 5 = 1
        uint256 eth_amount = (amount * address(this).balance) / totalLiquidity;
        //1 * 10000 / 5 = 2000
        uint256 token_amount = (amount * token_reserve) / totalLiquidity;
        //only this contract controls the burning and minting of LP tokens.
        (bool success, ) = LPTokenAddress.call(
            abi.encodeWithSignature("burnTokensTo(address,uint256)", msg.sender, amount)
        );
        require(success, "burn tx failed");
        totalLiquidity = totalLiquidity - amount;
        payable(msg.sender).transfer(eth_amount);
        require(token.transfer(msg.sender, token_amount));
        emit Withdrawed(msg.sender, eth_amount, token_amount);
        return (eth_amount, token_amount);
    }

    /// @notice Function thats called when performing exchanges that calculates the return amount based on the constant product market making algorithm.
    /// @dev The same formula is used for both types of exchanges, the inputs are set acordingly in the previous function call.
    /// @param a The amount of asset 1 added to the pool.
    /// @param x The reserve amount of asset 1 prior to the exchange.
    /// @param y The reserve amount of asset 2 prior to the exchange,
    /// @return The amount of asset 2 taken out of the pool and transfered to the user for the exchanged asset 1.
    function price(uint256 a, uint256 x, uint256 y) private pure returns (uint256) {
        //the constant k remains the same
        // x * y = k
        // x * y = x' * y'

        //the amount of tokens we recieve depends on the multiplication of x and y to mantain the constant
        // x' * y' = k
        //a is the token amount we input in the exchange
        // x + a = x'
        //b is the token amount we recieve
        // y - b = y'

        //(x + a)(y - b) = k

        //solving to b we deduce:
        //b = (y * a) / (x + a)

        //with the 0,3% trading fee:
        //b = (y * a * 0,997) / (x + a * 0,997)

        uint256 input_with_fee = a * 997;
        uint256 numerator = y * input_with_fee;
        uint256 denominator = x * 1000 + input_with_fee;
        return numerator / denominator;
    }

    /// @notice Function thats previews the DEX token amount returned for a ETH amount exchanged, without changing state.
    /// @dev Used to certify correct calculation off-chain
    /// @param msgValue The amount of ETH the user would be sending to exchange in a ethToToken call as msg.value
    /// @return The amount of tokens the user would recieve in return for the ETH amount inputed.
    function ethToTokenView(uint256 msgValue) public view returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        //ETH is X, tokens are Y
        //y - b = y'
        //how many tokens are we getting?
        uint256 tokensBought = price(msgValue, address(this).balance, tokenReserve); // a , x=x'- a, y

        return tokensBought;
    }

    /// @notice Function thats previews the ETH amount returned for DEX token amount exchanged, without changing state.
    /// @dev Used to certify correct calculation off-chain
    /// @param tokens The amount of tokens we would be exchanging.
    /// @return The amount of ETH the user would recieve in return for the DEX token amount inputed.
    function tokenToEthView(uint256 tokens) public view returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        //in this case, tokens is X, Y is eth
        //y - b = y'
        //how many ETH are we getting?
        uint256 ethBought = price(tokens, tokenReserve, address(this).balance); // a , x, y
        return ethBought;
    }

    //getters
    function getLiquidity() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalLiquidity() public view returns (uint256) {
        return totalLiquidity;
    }

    function getTokenReserves() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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