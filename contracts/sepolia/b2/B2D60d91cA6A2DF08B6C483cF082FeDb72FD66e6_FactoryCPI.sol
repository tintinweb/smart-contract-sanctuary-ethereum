//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MonthlyCPI.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title FactoryCPI contract
/// @author wildanvin
/// @notice This contract will create MonthlyCPI.sol every month 
/// @notice The percentage array is where the inlfation percentages change will be stored
contract FactoryCPI is ERC20 {

    constructor() ERC20("InfCOL", "ICOP") {
        _mint(0xDead0000371e0a9EC309d84586dE645a6897E613, 1000 * 10 ** decimals());

        //Genesis Month
        MonthlyCPI cpi = new MonthlyCPI(address(this));
        cpis.push(cpi);
    }

    struct Percentages {
        int price0;
        int price1;
        int price2;
        int price3;
        int total;
    }

    MonthlyCPI[] public cpis;
    Percentages[] public percentages;
    
    /// @notice This counter variable is important because it allows us to be in the right month for performing calculations
    uint public counter;

    modifier onlyOnceAMonth {
        require (block.timestamp >= MonthlyCPI(cpis[counter]).timeAtDeploy() + 28 days, "Only 1 per month");
        _;
    }

    modifier onlyAfterCommitReveal {
        require (block.timestamp >= MonthlyCPI(cpis[counter]).timeAtDeploy() + 6 days, "Wait for commit-reveal");
        _;
    }

    /// @notice This function should be called the 15th of each month by Chainlink Automation
    function createMonthlyCPI () public onlyOnceAMonth {
        MonthlyCPI cpi = new MonthlyCPI(address(this));
        cpis.push(cpi);
        counter++;
    }

    /// @notice This is the function that should be called the 21th of each month. After the commit-reveal period (6 days)
    /// @notice The percentages are multiplied by 100000 before dividing to don't lose precision
    function calculateCPI () public onlyAfterCommitReveal{

        int price0Old = int(MonthlyCPI(cpis[counter - 1]).price0Avg());
        int price1Old = int(MonthlyCPI(cpis[counter - 1]).price1Avg());
        int price2Old = int(MonthlyCPI(cpis[counter - 1]).price2Avg());
        int price3Old = int(MonthlyCPI(cpis[counter - 1]).price3Avg());

        (uint price0New, uint price1New, uint price2New, uint price3New) = MonthlyCPI(cpis[counter]).computeAvg();

        int percentage0 = ((int(price0New) - price0Old)*100000)/price0Old;
        int percentage1 = ((int(price1New) - price1Old)*100000)/price1Old;
        int percentage2 = ((int(price2New) - price2Old)*100000)/price2Old;
        int percentage3 = ((int(price3New) - price3Old)*100000)/price3Old;

        int total = (percentage0 + percentage1 + percentage2 + percentage3)/4;

        percentages.push(Percentages(percentage0, percentage1, percentage2, percentage3, total));
    }

    /// @notice This function allows an honest user to claim a reward
    /// @notice We divide inflation by 100000 to get the "actual" inflation percentage
    function claimReward () public onlyAfterCommitReveal{
        
        require(MonthlyCPI(cpis[counter]).userRevealed(msg.sender), "User hasn't revealed");
        require(MonthlyCPI(cpis[counter]).rewardClaimed(msg.sender) == false, "Already claimed");

        require(_verifyRevealedAnswers(), "Wrong answers submitted");

        int inflation = percentages[counter - 1].total;
        if ( inflation > 0) {
            uint totalParticipants = MonthlyCPI(cpis[counter]).getTotalParticipants();
            uint reward = (uint(inflation) * totalSupply())/(totalParticipants*100000);
            MonthlyCPI(cpis[counter]).setReward(msg.sender);
            _mint(msg.sender, uint(reward));
        }
    } 

    /// @notice This function returns true if the prices revealed by the user are in +10% or -10% range 
    function _verifyRevealedAnswers() view internal returns(bool) {
        (uint price0Reveal, uint price1Reveal, uint price2Reveal, uint price3Reveal) = MonthlyCPI(cpis[counter]).getRevealedPrices(msg.sender);

        (uint price0Avg, uint price1Avg, uint price2Avg, uint price3Avg) = MonthlyCPI(cpis[counter]).getAvgPrices();

        uint threshold0 = (price0Avg*10)/100;
        uint threshold1 = (price1Avg*10)/100;
        uint threshold2 = (price2Avg*10)/100;
        uint threshold3 = (price3Avg*10)/100;

        if (
            _positiveSubstraction(price0Avg,price0Reveal) <= threshold0 &&
            _positiveSubstraction(price1Avg,price1Reveal) <= threshold1 &&
            _positiveSubstraction(price2Avg,price2Reveal) <= threshold2 &&
            _positiveSubstraction(price3Avg,price3Reveal) <= threshold3
            )
        {
            return true;
        }else {
            return false;
        }

    }

    /// @notice Function helper to get a positive value in a substraction. Similar to an absolute value in math. Seems to work fine 
    function _positiveSubstraction (uint a, uint b) internal pure returns (uint){
        if (a < b){
            return (b-a);
        } else {
            return (a-b);
        }  
    }

    function getCPIsArray () public view returns (MonthlyCPI[] memory){
        return cpis;
    }

    function getPercentagesArray () public view returns (Percentages[] memory){
        return percentages;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title MonthlyCPI contract
/// @author wildanvin
/// @notice This contract will hold the average prices.
/// @notice The users will interact with an instance of this contract each month to commit and reveal prices
contract MonthlyCPI {

    struct RevealedPrice {
        uint price0;
        uint price1;
        uint price2;
        uint price3;
    }

    mapping (address => bytes32) public commitment;
    mapping (address => RevealedPrice) public revealedPrice;
    mapping (address => bool) public userRevealed;
    mapping (address => bool) public rewardClaimed;

    address[] public revealedUsers;
    address public factoryAddress;

    /// @notice These are the genesis month prices:
    uint public price0Avg = 700  * 10**18;  //$700 colombian pesos for 1 kw-hour
    uint public price1Avg = 3100 * 10**18;  //$3100 comlombian pesos for 1 liter of gas
    uint public price2Avg = 4600 * 10**18;  //$4600 colombian pesos for 1 liter of milk
    uint public price3Avg = 75000  * 10**18;  //$75000 colombian pesos for Internet 10 mbps upload speed (1 month)
    uint public timeAtDeploy;

    modifier notRevealed {
        require (!userRevealed[msg.sender], "Already revealed");
        _;
    }

    modifier onlyInCommitPeriod {
        require (block.timestamp <= timeAtDeploy + 3 days ,"Not time for commit");
        _;
    }

    modifier onlyInRevealPeriod {
        require (block.timestamp >= timeAtDeploy + 3 days && block.timestamp <= timeAtDeploy + 6 days,"Not time for reveal");
        _;
    }

    modifier onlyFactory {
        require (msg.sender == factoryAddress, "Not Factory");
        _;
    }

    constructor (address _factoryAddress) {
        timeAtDeploy = block.timestamp;
        factoryAddress = _factoryAddress;
    }


    
    /// @notice The client app implements: ethers.utils.solidityPack(["uint256", "uint256", "uint256", "uint256"],[price0, price1, price2, price3]);
    /// @param _commitment The bytes32 computed in the front end
    function commit (bytes32 _commitment) public onlyInCommitPeriod {
        require (commitment[msg.sender] == 0,"Already commited");
        commitment[msg.sender] = _commitment;
    }

    /// @notice This function is called with the prices. It accepets it only if it matches the prices in the commit
    function reveal (uint _price0, uint _price1, uint _price2, uint _price3) public notRevealed onlyInRevealPeriod {
        require (keccak256(abi.encodePacked(_price0, _price1 , _price2, _price3)) == commitment[msg.sender], "Incorrect commit");
    
        revealedPrice[msg.sender] = RevealedPrice({price0: _price0, price1: _price1, price2: _price2, price3: _price3});
        revealedUsers.push(msg.sender);
        userRevealed[msg.sender] = true;
    }

    /// @notice This function computes the average of the prices that have been reveled
    /// @notice The average is a poor way of implementation because a very big number can move the average by a lot, affecting the protocol. In the future will be better if the mean is implemented
    function computeAvg () public returns (uint, uint, uint, uint) {
        uint totalParticipants = revealedUsers.length;
        require(totalParticipants > 0, "No participants :(");
        
        uint price0Sum;
        uint price1Sum;
        uint price2Sum;
        uint price3Sum;

        for (uint i = 0; i < totalParticipants; i++) {

            price0Sum += revealedPrice[revealedUsers[i]].price0;
            price1Sum += revealedPrice[revealedUsers[i]].price1;
            price2Sum += revealedPrice[revealedUsers[i]].price2;
            price3Sum += revealedPrice[revealedUsers[i]].price3;

        }
        
        price0Avg = price0Sum/totalParticipants;
        price1Avg = price1Sum/totalParticipants;
        price2Avg = price2Sum/totalParticipants;
        price3Avg = price3Sum/totalParticipants;

        return (price0Avg, price1Avg, price2Avg, price3Avg);
    }  

    /// @notice This function will be called by the factory contract. It is a way to make that the user only claim once per MonthlyCPI 
    /// @param _claimer Address of claimer passed from FactoryCPI contract
    function setReward(address _claimer) public onlyFactory {
        rewardClaimed[_claimer] = true;
    }

    /// @notice I used this function to verify that the commit from the front-end and from solidity is actually the same 
    function testHash (uint _price0, uint _price1 , uint _price2, uint _price3) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_price0, _price1 , _price2, _price3));
    }

    function getRevealedPrices (address _address) external view returns (uint, uint, uint, uint)  {

        uint v0 = revealedPrice[_address].price0;
        uint v1 = revealedPrice[_address].price1;
        uint v2 = revealedPrice[_address].price2;
        uint v3 = revealedPrice[_address].price3;

        return (v0, v1, v2, v3);
    }

    function getAvgPrices () external view returns (uint, uint, uint, uint)  {
        return (price0Avg, price1Avg, price2Avg, price3Avg);
    }

    function getTotalParticipants () public view returns (uint) {
        return revealedUsers.length;
    }
}