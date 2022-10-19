// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract Token is ERC20 {
//     constructor () ERC20("AAA", "VVVV"){}
// }
contract TokenTest {
    uint256 public totalSuply;

    constructor () {
        totalSuply = 9999;
    }

    address public my ;
    function set(address eee)  public {
        my = eee;
    }

    function modifyIt(uint256 num) public {
        totalSuply = num;
    }

    function editHouseEdge(uint16 houseEdge) external {
    }

    function returnSignature() public pure returns (bytes4, bytes4){
        bytes4 functionSignature1 = bytes4(keccak256("editHouseEdge(uint16)"));
        bytes4 functionSignature2 = bytes4(this.editHouseEdge.selector);
        return (functionSignature1, functionSignature2); // returns 0x2b018a35
    }

    // fucntion encodeCall() public pure returns (bytes memory){
    //     return abi.encodecall
    // }

    function encodeWithSignature (address to,uint amount)
        private
        pure
        returns ( bytes memory ){
        
        return abi.encodeWithSignature("transfer(address,uint256)",to,amount);
    }

    function encodeWithSelector(address to, uint amount) private pure returns (bytes memory){
        return abi.encodeWithSelector(IERC20.transfer.selector, to, amount);
    }

    // function encodeCall(address to, uint amount) private pure returns (bytes memory){
    //     return abi.encodeCall(IERC20.transfer, (to, amount));
    // }

    function encodeP(uint256 amount, address account) external pure returns (bytes memory){
        // return abi.encodePacked(account, amount);
        return abi.encodePacked("\x19Ethereum Signed Message:\n32"); 
        // 0x19457468657265756d205369676e6564204d6573736167653a0a3332
        // 0x19457468657265756d205369676e6564204d6573736167653a0a
        // 0x19457468657265756d205369676e6564204d6573736167653a0a3332
    }

      function encodePHashed() external pure returns (bytes32 hash1, bytes32 hash2){
        uint256 amount = 1000000000000000000;
        address account = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        hash1 = keccak256(abi.encodePacked(account, amount));
        hash2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash1));
        return (hash1, hash2);
    }

    // 1000000000000000000
    // 0x90F79bf6EB2c4f870365E785982E1f101E93b906

    //hash1: 0xfe9d830bb73879a37726b26fecf3b43dff1c02fb870ca1b6d5e2ab3ab5461819
    //hash2: 0x1be97aac75ccdf1ac0b8e52ff6e2529d17a024fccf0f90eb6ce4e0d195870961
    bytes32 public varu; // 0x0000000000000000000000000000000000000000000000000000000000000000
    function checkBytes() public pure returns (bool){
        bytes32 local = 0x1000000000000000000000000000000000000000000000000000000000000000;
        return local == bytes32(0);
    }

    function THISreturnEncoded() public pure returns (bytes memory, bytes memory){
        string memory text = "h";
        return (abi.encode(text), abi.encodePacked(text));
    }
    address public president;

    function calculateGasStateChange(address user) public view returns (uint256){
        // if(president == address(0)){}
        if(user.code.length > 0){
            return 1;
        }else  return 2;
        // president = user ;
    }

    int256 public num = int256(uint256(90000));
    
    function basereturnCorrect1() public pure{
        uint256 num = 1;
        return;
    }
    address[] public influencers;

    function addInfluencers(address influencer) public{
        influencers.push(influencer);
    }


    function getInfluencers() public view returns (address[] memory){
        // address[] memory list = new address[](influencers.length); 
        // list = influencers;
        return influencers;
        // list = influencers;
        // return influencers;
    }
    // 23980
    // 23980
    // 44120
    // 21980
    // 21953
    address[] public s_addedTokens;
    mapping(address=>Token) public s_tokenData;
    mapping(address => int256) totalInfluencerProfit; // token=> amount
    struct Token {
        bool isEnabled;
        address usdPriceFeed;
    }


    function runSetup() public {
        s_addedTokens.push(0x3EFC72fF137A5603Ce2E7108a70e56CAb49bf1e2);
        s_addedTokens.push(0x7e9dA1907219DB8aff54e2aA35F72477A92C16ED);
        s_addedTokens.push(0x4e222A1EB914327b57F2b7F9d427D800C5016B89);
        // s_addedTokens.push(0xaF6f81149F0e937E8d84C683ACF233B2C05FD4e0);
        s_addedTokens.push(0xaF6f81149F0e937E8d84C683ACF233B2C05FD4e0);
        // s_addedTokens.push(address(0));
        

        // totalInfluencerProfit[address(0)] = 100 * 1e18;
        // totalInfluencerProfit[0x3EFC72fF137A5603Ce2E7108a70e56CAb49bf1e2] = 11 * 1e18;
        // totalInfluencerProfit[0x7e9dA1907219DB8aff54e2aA35F72477A92C16ED] = -100 * 1e18;
        // totalInfluencerProfit[0x4e222A1EB914327b57F2b7F9d427D800C5016B89] = -10 * 1e18;


        totalInfluencerProfit[0x3EFC72fF137A5603Ce2E7108a70e56CAb49bf1e2] = 99 * 1e3;
        totalInfluencerProfit[0x7e9dA1907219DB8aff54e2aA35F72477A92C16ED] = -100 * 1e3;
        totalInfluencerProfit[0x4e222A1EB914327b57F2b7F9d427D800C5016B89] = -10 * 1e3;
        totalInfluencerProfit[0xaF6f81149F0e937E8d84C683ACF233B2C05FD4e0] = 111 * 1e3;

        // totalInfluencerProfit[0x3EFC72fF137A5603Ce2E7108a70e56CAb49bf1e2] = 99 * 1e18;
        // totalInfluencerProfit[0x7e9dA1907219DB8aff54e2aA35F72477A92C16ED] = -100 * 1e18;
        // totalInfluencerProfit[0x4e222A1EB914327b57F2b7F9d427D800C5016B89] = -10 * 1e18;
        // totalInfluencerProfit[0xaF6f81149F0e937E8d84C683ACF233B2C05FD4e0] = 111 * 1e18;

        // negative profit
        // totalInfluencerProfit[address(0)] = 100 * 1e18;
        // totalInfluencerProfit[0x3EFC72fF137A5603Ce2E7108a70e56CAb49bf1e2] = 9 * 1e18;
        // totalInfluencerProfit[0x7e9dA1907219DB8aff54e2aA35F72477A92C16ED] = -100 * 1e18;
        // totalInfluencerProfit[0x4e222A1EB914327b57F2b7F9d427D800C5016B89] = -10 * 1e18;
    } 
    
    function mytest()
        public
        pure
        returns (address[] memory, uint256[] memory)
    {
        address[] memory tokens;
        uint256[] memory amounts;
        tokens[0] = address(0);
        tokens[1] = address(4);
        amounts[0] = 123;
        amounts[1] = 123;

        // ens = new address[](2);
        // uint256[] memory amounts = new uint256[](2);
        // tokens[0] = address(0);
        // tokens[1] = address(4);
        // amounts[0] = 123;
        // amounts[1] = 123;
        return (tokens, amounts);
    }

    event JustPrint(int256 num);

    uint256 public num4 = uint8(100);  


    function getGeneralInfluencerProfitInUsd()
        public
        view
        // returns (int256)
        returns (address[] memory, uint256[] memory )
        // returns (address[] memory, int256[] memory, int256[] memory)
    {
        int256 total;
        uint256 tokensLength = s_addedTokens.length;
        uint32 counter1;
        address[] memory tokenAddresses = new address[](tokensLength);
        int256[] memory tokenAmounts = new int256[](tokensLength);
        int256[] memory usdPrices = new int256[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            address currentToken = s_addedTokens[i];
            // Token memory token = s_tokenData[currentToken];
            // uint8 decimals = AggregatorV3Interface(token.usdPriceFeed)
                // .decimals();
            // (, int256 answer, , , ) = AggregatorV3Interface(token.usdPriceFeed)
                // .latestRoundData();
            uint8 decimals = 8;
            int256 answer = 129362900000; // 1293,62900000 // 14.229,919
            // -1,293629E21
            // -1,293629E21

            // TODO: Test with negative and positive
            // int256 tokenAmount = influencerData[influencer]
            //     .totalInfluencerProfit[currentToken];
            // 100 * 1e18 =  (1E20 * 129362900000)/1e8 = 1,293629E23
            // 9 * 1e18 =  (9E18 * 129362900000)/1e8 = 1,1642661E22
            // -100 * 1e18 = (-1E20 * 129362900000)/1e8 = -1,293629E23
            // -10 * 1e18 = (-1E19 * 129362900000)/1e8 = -1,293629E22
            // 1,293629E23 + 1,1642661E22 - -1,293629E23 1,293629E22= -1,293629E21
            int256 tokenAmount = totalInfluencerProfit[currentToken]; // edited
            int256 usdPrice = (tokenAmount * answer) / int256(10**decimals);
            // int256 usdPrice = ((tokenAmount * answer) / int256(10**decimals))/1e18;
            // Adds to the total
            // usdPrice > 0 ? total += usdPrice : total -= usdPrice;
            total += usdPrice;
            if (usdPrice > 0) {
                tokenAddresses[counter1] = currentToken;
                tokenAmounts[counter1] = tokenAmount;
                usdPrices[counter1] = usdPrice;
                counter1++;
            }
        }
        // return (tokenAddresses, tokenAmounts, usdPrices);
        // The total in USD is less negative
        // return total;
        
        if (total < 0) {
            address[] memory tokensEmpty;
            uint256[] memory amountsEmpty;
            return (tokensEmpty, amountsEmpty);
        }
        address[] memory tokens = new address[](usdPrices.length);
        uint256[] memory amounts = new uint256[](usdPrices.length);
        uint256 paymentTotal;
        uint32 counter2;
        // The total in USD is positive, create transfer intructions
        for (uint256 i = 0; i < usdPrices.length; i++) {
            if (usdPrices[i] <= 0) continue; // Skips the empty ones
            tokens[counter2] = tokenAddresses[i];
            
            if (uint256(total) >= (paymentTotal + uint256(usdPrices[i]))) {
                amounts[counter2] = uint256(tokenAmounts[i]);
                if(uint256(total) == (paymentTotal + uint256(usdPrices[i]))){
                    return (tokens, amounts);
                }
                paymentTotal += uint256(usdPrices[i]);
            } 
            else {
                uint256 missingAmountUSD = (uint256(total) - paymentTotal);
                amounts[counter2] =  ((uint256(tokenAmounts[i]) * 1e18 / uint256(usdPrices[i])) * missingAmountUSD)/1e18;
                return (tokens, amounts);
            }
            counter2++;
        }
        return (tokens, amounts);

    }
    uint256 public obtain = 10;
    bool one1;
    bool one2;
    bool one3;
    function getObtain() public  returns (bool, bool ,bool){
        one1 = obtain++ > 10;
        one2 = obtain++ > 11;
        one3 = obtain++ > 12;
        return (one1, one2, one3);
    }
    event Print(uint256 indexed, uint256 indexed, uint256 indexed, uint256);
    function print(uint256 times) public {
        for(uint256 i; i< times; i++){
            one1 = !one1;
            one2 = !one3;
            one3 = !one2;
            emit Print(1,2,3,4);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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