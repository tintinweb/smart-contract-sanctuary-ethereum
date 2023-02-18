/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/LendingAndBorrowing.sol


pragma solidity >=0.4.22 <0.9.0;



// Set up you contract to convert DAI to USD or ETH to USD
contract LendingAndBorrowing is Ownable {
    address[] public lenders;
    address[] public borrowers;

    mapping(address => mapping(address => uint256)) public tokensLentAmount;
    mapping(address => mapping(address => uint256)) public tokensBorrowedAmount;
    mapping(uint256 => mapping(address => address)) public tokensLent;
    mapping(uint256 => mapping(address => address)) public tokensBorrowed;
    mapping(address => address) public tokenToPriceFeed;
    mapping(uint256 => mapping(address => address)) public tokensLentOrBorrowed;

    event Withdraw(address sender, uint256 amount, uint256 tokenToWithdrawInDollars, uint256 availableToWithdraw, uint256 totalAmountLentInDollars, uint256 interestTokenToRemove);
    event PayDebt(address sender, int256 index, uint256 tokenAmountBorrowed, uint256 totalTokenAmountToCollectFromUser, address[] borrowers);
    event Borrow(address sender, uint256 amountInDollars, uint256 totalAmountAvailableForBorrowInDollars, bool userPresent, int256 userIndex, address[] borrowers, uint256 currentUserTokenBorrowedAmount);
    event Supply(address sender, address[] lenders, uint256 currentUserTokenLentAmount);
    event WithdrawTesting(address sender, uint256 tokentoWithdrawInDollars, uint256 availableToWithdraw);
    event BorrowTesting1(address sender, uint256 amountInDollars, uint256 totalAmountAvailableForBorrowInDollars);
    event BorrowTesting2(address sender, uint256 balance, uint256 amount);
    event RepayTesting1(address sender, int256 index);
    event RepayTesting2(address sender, uint256 tokenBorrowed);

    struct Token {
        address tokenAddress; 
        uint256 LTV; 
        uint256 stableRate; 
        string name;
    }

    Token[] public tokensForLending;
    Token[] public tokensForBorrowing;

    IERC20 public interestToken;

    uint256 public noOfTokensLent;
    uint256 public noOfTokensBorrowed;

    constructor(address _token) {
        interestToken = IERC20(_token);
    }

    /** 
     * @dev This function is to add a token to the list of tokens that can be lent
     * @param name The name of the token
     * @param tokenAddress The address of the token
     * @param LTV The Loan to Value, the percentage of the token that can be lent. For example, if the LTV is 50, then 50% of the value can be lent.
     * @param borrowStableRate The stable rate at which the token can be borrowed     
     */
    function addTokensForLending(string memory name, address tokenAddress, uint256 LTV, uint256 borrowStableRate) public onlyOwner {
        Token memory token = Token(tokenAddress, LTV, borrowStableRate, name);

        if (!tokenIsAlreadyThere(token, tokensForLending)) {
            tokensForLending.push(token);
        }
    }

    /**
     * @dev This function is to add a token to the list of tokens that can be borrowed
     * @param name The name of the token
     * @param tokenAddress The address of the token
     * @param LTV The Loan to Value, the percentage of the token that can be borrow. For example, if the LTV is 50, then 50% of the value can be borrow.
     */
    function addTokensForBorrowing(string memory name, address tokenAddress, uint256 LTV, uint256 borrowStableRate) public onlyOwner {
        Token memory token = Token(tokenAddress, LTV, borrowStableRate, name);

        if(!tokenIsAlreadyThere(token, tokensForBorrowing)){
            tokensForBorrowing.push(token);
        }
    }

    function lend(address tokenAddress, uint256 amount) public payable {
        require(tokenIsAllowed(tokenAddress, tokensForLending), "Token is not supported"
        );

        require(amount > 0, "The amount to supply should be greater than 0");

        IERC20 token = IERC20(tokenAddress);

        require(token.balanceOf(msg.sender) >= amount, "You have insufficient token to supply that amount");

        token.transferFrom(msg.sender, address(this), amount);

        (bool userPresent, int256 userIndex) = isUserPresentIn(msg.sender, lenders);

        if(userPresent){
            updateUserTokensBorrowedOrLent(tokenAddress, amount, userIndex, "lenders");
        } else {
            lenders.push(msg.sender);
            tokensLentAmount[tokenAddress][msg.sender] = amount;
            tokensLent[noOfTokensLent++][msg.sender] = tokenAddress;
        }

        rewardUserToken(msg.sender, tokenAddress, amount);

        emit Supply(msg.sender, lenders, tokensLentAmount[tokenAddress][msg.sender]);
    }

    function borrow(uint256 amount, address tokenAddress) public {
        require(tokenIsAllowed(tokenAddress, tokensForBorrowing), "Token is not supported for borrowing");
        require(amount > 0, "Amount should be greater than 0");

        uint256 totalAmountAvailableForBorrowInDollars = getUserTotalAmountAvailableForBorrowInDollars(msg.sender);
        uint256 amountInDollars = getAmountInDollars(amount, tokenAddress);

        require(amountInDollars <= totalAmountAvailableForBorrowInDollars, "You don't have enough collateral to borrow this amount");

        IERC20 token = IERC20(tokenAddress);

        require(token.balanceOf(address(this)) >= amount, "We do not have enough of this token for you to borrow.");

        token.transfer(msg.sender, amount);

        (bool userPresent, int256 userIndex) = isUserPresentIn(msg.sender, borrowers);

        if(userPresent){
            updateUserTokensBorrowedOrLent(tokenAddress, amount, userIndex, "borrowers");
        } else {
            borrowers.push(msg.sender);
            tokensBorrowedAmount[tokenAddress][msg.sender] = amount;
            tokensBorrowed[noOfTokensBorrowed++][msg.sender] = tokenAddress;
        }

        emit Borrow(msg.sender, amountInDollars, totalAmountAvailableForBorrowInDollars, userPresent, userIndex, borrowers, tokensBorrowedAmount[tokenAddress][msg.sender]);
    }

    function oneTokenEqualsHowManyDollars(address tokenAddress) public view returns(uint256 price, uint256 decimals) {
        
        uint256 tokenDecimals = IERC20Metadata(tokenAddress).decimals();
        uint256 tokenPrice = 1;

        return (tokenPrice, tokenDecimals);
    }

    function payDebt(address tokenAddress, uint256 amount) public {
        require(amount > 0, "Amount should be greater than 0");
        int256 index = indexOf(msg.sender, borrowers);
    
        require(index >= 0, "User address is not found in the list of borrowers");

        uint256 tokenBorrowed = tokensBorrowedAmount[tokenAddress][msg.sender];        

        require(tokenBorrowed > 0, "You  are not owing");

        IERC20 token = IERC20(tokenAddress);

        uint256 totalTokenAmountToCollectFromUser = amount + interest(tokenAddress, tokenBorrowed);

        token.transferFrom(msg.sender, address(this), totalTokenAmountToCollectFromUser);

        tokensBorrowedAmount[tokenAddress][msg.sender] = tokensBorrowedAmount[tokenAddress][msg.sender] - amount;

        // Check If all the amount borrowed = 0;
        uint256 totalAmountBorrowed = getTotalAmountBorrowedInDollars(msg.sender);

        if(totalAmountBorrowed == 0){
            borrowers[uint256(index)] = borrowers[borrowers.length - 1];
            borrowers.pop();
        }

        emit PayDebt(msg.sender, index, tokenBorrowed, totalTokenAmountToCollectFromUser, borrowers);
    }

    function withdraw(address tokenAddress, uint256 amount) public {
        require(amount > 0, "Amount should be greater than 0");

        int256 index = indexOf(msg.sender, lenders);

        require(index >= 0, "User address is not found in the list of lenders");

        IERC20 token = IERC20(tokenAddress);

        uint256 tokenToWithdrawInDollars = getAmountInDollars(amount, tokenAddress);
        uint256 availableToWithdraw = getTokenAvailableToWithdraw(msg.sender);

        uint totalTokenSuppliedInContract = getTotalTokenSupplied(tokenAddress);
        uint totalTokenBorrowedInContract = getTotalTokenBorrowed(tokenAddress);

        require(amount <= (totalTokenSuppliedInContract - totalTokenBorrowedInContract));

        require(tokenToWithdrawInDollars <= availableToWithdraw, "You have used some of your supplies as your collateral. Pay your debt before you can be allowed to withdraw. Thanks");

        uint256 interestTokenToRemove = getAmountInDollars(amount, tokenAddress);
        uint256 interestTokenBalance = interestToken.balanceOf(msg.sender);

        if (interestTokenToRemove <= interestTokenBalance) {
            interestToken.transferFrom(msg.sender, address(this), interestTokenToRemove);
        } else {
            interestToken.transferFrom(msg.sender, address(this), interestTokenBalance);
        }

        token.transfer(msg.sender, amount);

        tokensLentAmount[tokenAddress][msg.sender] = tokensLentAmount[tokenAddress][msg.sender] - amount;

        uint256 totalAmountLentInDollars = getTotalAmountLentInDollars(msg.sender);

        if (totalAmountLentInDollars <= 0) {
            lenders[uint256(index)] = lenders[lenders.length - 1];
            lenders.pop();
        }

        emit Withdraw(msg.sender, amount, tokenToWithdrawInDollars, availableToWithdraw, totalAmountLentInDollars, interestTokenToRemove);

    }

    function getTokenAvailableToWithdraw(address user) public view returns (uint256){
        
        uint256 totalAmountBorrowedInDollars = getTotalAmountBorrowedInDollars(user);

        uint remainingCollateral = 0;

        if (totalAmountBorrowedInDollars > 0 ){
            remainingCollateral = getRemainingCollateral(user);
        }else{
            remainingCollateral = getTotalAmountLentInDollars(user);
        }


        if (remainingCollateral < totalAmountBorrowedInDollars){
            return 0;
        }

        uint256 availableToWithdraw = remainingCollateral - totalAmountBorrowedInDollars;

        return availableToWithdraw;
    }

 function getRemainingCollateral(address user) public view returns (uint256){
        uint256 remainingCollateral = 0;
        for (uint256 i = 0; i < noOfTokensLent; i++) {
            address userLentTokenAddressFound = tokensLent[i][user];

            if (userLentTokenAddressFound != address(0)){                
                Token memory currentTokenFound = getTokenFrom(userLentTokenAddressFound);                
                uint256 tokenAmountLent = tokensLentAmount[userLentTokenAddressFound][user];
                uint256 tokenAmountLentInDollars = getAmountInDollars(tokenAmountLent, userLentTokenAddressFound);
                remainingCollateral += (tokenAmountLentInDollars * currentTokenFound.LTV) / 10 ** 18;
            }
        }
        return remainingCollateral;
    }

    function indexOf(address user, address[] memory addressArray) pure public returns (int256){
        int256 index = -1;

        for (uint256 i = 0; i < addressArray.length; i++) {
            address currentAddress = addressArray[i];
            if (currentAddress == user) {
                return int256(i);
            }
        }
        return index;
    }


    function getTotalAmountBorrowedInDollars(address user) public view returns (uint256){
        uint256 totalAmountBorrowed = 0;

        for (uint256 i = 0; i < noOfTokensBorrowed; i++) {
            address userBorrowedTokenAddressFound = tokensBorrowed[i][user];

            if (userBorrowedTokenAddressFound != address(0)) {
                uint256 tokenAmountBorrowed = tokensBorrowedAmount[userBorrowedTokenAddressFound][user];
                uint256 tokenAmountBorrowedInDollars = getAmountInDollars(tokenAmountBorrowed, userBorrowedTokenAddressFound);
                totalAmountBorrowed += tokenAmountBorrowedInDollars;
            }
        }
        return totalAmountBorrowed;
    }

    function getTotalAmountLentInDollars(address user) public view returns (uint256){
        uint256 totalAmountLent = 0;
        for (uint256 i = 0; i < noOfTokensLent; i++) {
            address userLentTokenAddressFound = tokensLent[i][user];

            if (userLentTokenAddressFound != address(0)) {
                uint256 tokenAmountLent = tokensLentAmount[userLentTokenAddressFound][user];
                uint256 tokenAmountLentInDollars = getAmountInDollars(tokenAmountLent, userLentTokenAddressFound);
                totalAmountLent += tokenAmountLentInDollars;
            }
        }
        return totalAmountLent;
    }

    function interest(address tokenAddress, uint256 tokenBorrowed) public view returns (uint256){
        Token memory token = getTokenFrom(tokenAddress);
        return (tokenBorrowed * token.stableRate) / 10**18;
    }

    function getTokenFrom(address tokenAddress) public view returns (Token memory){
        Token memory token;
        for (uint256 i = 0; i < tokensForBorrowing.length; i++) {
            Token memory currentToken = tokensForBorrowing[i];
            if (currentToken.tokenAddress == tokenAddress) {
                token = currentToken;
                break;
            }
        }
        return token;
    }

    function getUserTotalAmountAvailableForBorrowInDollars(address user) public view returns (uint256){
        // uint256 totalAvailableToBorrow = 0;

        uint256 userTotalCollateralToBorrow = 0;
        uint256 userTotalCollateralAlreadyBorrowed = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            address currentLender = lenders[i];
            if (currentLender == user) {
                for (uint256 j = 0; j < tokensForLending.length; j++) {
                    Token memory currentTokenForLending = tokensForLending[j];
                    uint256 currentTokenLentAmount = tokensLentAmount[currentTokenForLending.tokenAddress][user];
                    uint256 currentTokenLentAmountInDollar = getAmountInDollars(currentTokenLentAmount, currentTokenForLending.tokenAddress);
                    uint256 availableInDollar = (currentTokenLentAmountInDollar * currentTokenForLending.LTV) / 10**18; 
                            
                        userTotalCollateralToBorrow += availableInDollar;
                }
            }
        }

        for (uint256 i = 0; i < borrowers.length; i++) {
            address currentBorrower = borrowers[i];
            if (currentBorrower == user) {
                for (uint256 j = 0; j < tokensForBorrowing.length; j++) {
                    Token memory currentTokenForBorrowing = tokensForBorrowing[j];
                    uint256 currentTokenBorrowedAmount = tokensBorrowedAmount[currentTokenForBorrowing.tokenAddress][user];
                    uint256 currentTokenBorrowedAmountInDollar = getAmountInDollars((currentTokenBorrowedAmount), currentTokenForBorrowing.tokenAddress);

                    userTotalCollateralAlreadyBorrowed += currentTokenBorrowedAmountInDollar;
                }
            }
        }

        return userTotalCollateralToBorrow - userTotalCollateralAlreadyBorrowed;
    }

    function tokenIsBorrowed(address user, address token) private view returns (bool){
        return tokensBorrowedAmount[token][user] != 0;
    }

    function tokenIsAllowed(address tokenAddress, Token[] memory tokenArray) private pure returns (bool){
        if (tokenArray.length > 0) {
            for (uint256 i = 0; i < tokenArray.length; i++) {
                Token memory currentToken = tokenArray[i];
                if (currentToken.tokenAddress == tokenAddress) {
                    return true;
                }
            }
        }

        return false;
    }

    function tokenIsAlreadyThere(Token memory token, Token[] memory tokenArray) private pure returns (bool){
        if (tokenArray.length > 0) {
            for (uint256 i = 0; i < tokenArray.length; i++) {
                Token memory currentToken = tokenArray[i];
                if (currentToken.tokenAddress == token.tokenAddress) {
                    return true;
                }
            }
        }

        return false;
    }

    function rewardUserToken(address user, address tokenAddress, uint256 amount) private {
        require(amount > 0, "Amount should be greater than 0");
        uint256 amountIndollars = getAmountInDollars(amount, tokenAddress);
        interestToken.transfer(user, amountIndollars);
    }

    function getAmountInDollars(uint256 amount, address tokenAddress) public view returns (uint256){
        (uint256 dollarPerToken, uint256 decimals) = oneTokenEqualsHowManyDollars(tokenAddress);
        uint256 totalAmountInDollars = (amount * dollarPerToken) / (10**decimals);
        return totalAmountInDollars;
    }

    function updateUserTokensBorrowedOrLent(address tokenAddress, uint256 amount, int256 userIndex, string memory lendersOrBorrowers) internal {
        
        if(keccak256(abi.encodePacked(lendersOrBorrowers)) == keccak256(abi.encodePacked("lenders"))){
            
            address currentUser = lenders[uint256(userIndex)];
            bool tokenLendedAlready = hasLentOrBorrowedToken(currentUser, tokenAddress, noOfTokensLent, "tokensLent");

            if(tokenLendedAlready){
                tokensLentAmount[tokenAddress][currentUser] = tokensLentAmount[tokenAddress][currentUser] + amount;
            } else {
                tokensLent[noOfTokensLent++][currentUser] = tokenAddress;
                tokensLentAmount[tokenAddress][currentUser] = amount;
            }

        }else if(keccak256(abi.encodePacked(lendersOrBorrowers)) == keccak256(abi.encodePacked("borrowers"))){
            
            address currentUser = borrowers[uint256(userIndex)];
            bool tokenBorrowedAlready = hasLentOrBorrowedToken(currentUser, tokenAddress, noOfTokensBorrowed, "tokensBorrowed");

            if (tokenBorrowedAlready) {
                tokensBorrowedAmount[tokenAddress][currentUser] = tokensBorrowedAmount[tokenAddress][currentUser] + amount;
            } else {
                tokensBorrowed[noOfTokensBorrowed++][currentUser] = tokenAddress;
                tokensBorrowedAmount[tokenAddress][currentUser] = amount;
            }
        }
    }

    function hasLentOrBorrowedToken(address currentUser, address tokenAddress, uint256 noOfTokenslentOrBorrowed, string memory _tokensLentOrBorrowed) public view returns (bool) {
        
        if (noOfTokenslentOrBorrowed > 0) {
            if (keccak256(abi.encodePacked(_tokensLentOrBorrowed)) == keccak256(abi.encodePacked("tokensLent"))){
                for(uint256 i = 0; i < noOfTokensLent; i++){
                    address tokenAddressFound = tokensLent[i][currentUser];
                    if (tokenAddressFound == tokenAddress) {
                        return true;
                    }
                }
            } else if (keccak256(abi.encodePacked(_tokensLentOrBorrowed)) == keccak256(abi.encodePacked("tokensBorrowed"))){
                for(uint256 i = 0; i < noOfTokensBorrowed; i++){
                    address tokenAddressFound = tokensBorrowed[i][currentUser];
                    if (tokenAddressFound == tokenAddress) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function isUserPresentIn(address userAddress, address[] memory users) private pure returns (bool, int256){
        if (users.length > 0) {
            for(uint256 i = 0; i < users.length; i++){
                address currentUserAddress = users[i];
                if (currentUserAddress == userAddress) {
                    return (true, int256(i));
                }
            }
        }
        return (false, -1);
    }

    function getTotalTokenSupplied(address tokenAddres) public view returns (uint256){
        uint256 totalTokenSupplied = 0;
        if (lenders.length > 0){
            for(uint256 i = 0; i < lenders.length; i++){
                address curentLender = lenders[i];
                totalTokenSupplied += tokensLentAmount[tokenAddres][curentLender];
            }
        }
        return totalTokenSupplied;
    }

    function getTotalTokenBorrowed(address tokenAddress) public view returns (uint256){
        uint256 totalTokenBorrowed = 0;
        if (borrowers.length > 0) {
            for (uint256 i = 0; i < borrowers.length; i++) {
                address curentBorrower = borrowers[i];
                totalTokenBorrowed += tokensBorrowedAmount[tokenAddress][curentBorrower];
            }
        }
        return totalTokenBorrowed;
    }
}