//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.7;

/**

 * KEYS: a kind of decentralized social network 
 *  
 *  
 * From Satoshi Nakamoto's release of Bitcoin: A Peer-to-Peer Electronic Cash System, 
 * there came out a new option to pay based on blockchain. 
 * It did not rely on any government credits, decentralization consensus built that. 
 * People seemed to see the dawn of a new world and talked about what else could be decentralized. 
 * Then, Ethereum emerged with a turing-complete EVM. EVM made onchain programming possible. 
 * The usage of blockchain from payment to explore more possibilities, such as ICO, DEFI, NFT, GAMEFI, etc.
 *  
 * During the process of exploration, some governments were increasingly accepting of cryptocurrency, 
 * and embraced decentralization; some governments that characterized cryptocurrency as financial derivatives, 
 * and wanted to centralize them into puppets; of course, there was no doubt that some authoritarian governments 
 * were afraid decentralization would impact their rule, 
 * and tried to kill decentralization by banning blockchain networks. 
 * However, no matter the governments' attitudes to decentralization, more and more people are embracing it. 
 * The users of cryptocurrency have reached hundreds of millions. It may be much less than the global population, 
 * but it is enough to show that the decentralization consensus is thriving and has become an unbreakable belief. 
 *  
 * Decentralization is creating a new world. In this new world, no one cares if you are white, black or yellow, 
 * no one cares  if you are American, Guinean or Chinese. Everyone will know you by what you do in this new world. 
 * Your assets are entirely your own, and no one can block your assets without your permission. 
 * Despite some governments attempting to restrict crypto assets that interact with Tornado cash by executive order, 
 * decentralization will never compromise with centralized power.
 *  
 * Surely, this new world itself still has a lot of problems, The DAO, DEFI hacking, LUNA, FTX, etc., 
 * all of which have had a great impact on the development of decentralization. However, historically, 
 * troubles do not cast doubt on our belief in decentralization, instead, 
 * they gather the wisdom of all decentralization believers to promote the healthy development of this new world.
 *  
 * Decentralization may not be a cure for the world, 
 * it is more about providing a different choice for freedom-loving people. 
 * It is important to have choices. People had to use centralized products before, because they had no choice.
 *  
 * The evolution of decentralization is still in its very early stages, 
 * even most decentralized communities are based on centralized platforms like Twitter, Discord, Telegram or whatever. 
 * Online networking is the key of running a decentralized community. 
 * However, there hasn't been a truly decentralized social network yet, 
 * and the vast amounts of social data we generate every day are still in the hands of centralized giants. 
 * These centralized giants monopolize users' social data, freely mine users' privacy to form so-called user profiles, 
 * recommend so-called personalized ads to users, and use user data to make huge profits under the guise of free. 
 * And they play the role of God in their apps, blocking whoever they want.
 *  
 * Obviously, people are likely to pay more to use these "free" social apps.
 *  
 * So, is it possible for us to create a decentralized social network driven by the community? 
 * Where there are no personalized recommendations, no network administrators, no such fucking ads. 
 * Who we want to talk to and who we don't, what we want to see and what we don't, it's all up to ourselves. 
 * Our assets and data really belong to ourselves, no one can steal it.
 *   
 * We designed a decentralized social network, let's call it the KEYS Network. 
 * The social network is completely owned by its users. In return, of course, users pay for the cost of data storage and transfer.
 *   
 * The construction of decentralized social network is divided into two parts: 
 * the decentralized blockchain network, the user client.
 *   
 * The decentralized blockchain network: 
 * Bitcoin and Ethereum have proven to everyone that they are secure and decentralized enough. 
 * Although the Bitcoin network has been running longer than the Ethereum network, 
 * it is clear that it is not practical to use the Bitcoin network as a decentralized social network. 
 * We tend to base on the Ethereum to build a decentralized social network, 
 * but Ethereum is expensive and heavy for social applications. 
 * Therefore, we plan to make some modifications based on Ethereum to build a new side chain, 
 * so that the new side chain can be more suitable for building social applications.
 * The modification mainly includes the following two aspects:
 * 1. Instead of EOAs and CAs, KEYS Network uses uniform accounts(UAs). 
 *    Implement account abstraction at the consensus layer so that KEYS Network can be mass adaption. 
 *    UAs have the features of EOAs and CAs. User can choose to keep the private key by themselves or 
 *    keep the private key into the contract and authenticate their identity through the contract programing. 
 * 2. All UAs have massage box, messages can be classified into private chat, group chat, Keys and public. 
 *    Private chat is permissionless point-to-point encrypted communication, 
 *    it means the message sender sends the message to the message receiver without the message receiver's permission. 
 *    Of course, in order to prevent the message receiver from being harassed by the message, it needs to cooperate with the client. 
 *    The new messages will be folded by default and will be displayed only when the message receiver active them. 
 *    Group chat and Keys are controlled and encrypted by tokens. Only users who have the same token can see them. 
 *    "Keys" is a new message format, it means things need more attention than common group chat message,
 *    such as proposals, announcements, or other things that group members should attention. 
 *    Also, in order to prevent the message receiver from being harassed by messages, 
 *    new group chat messages or Keys will be folded by default and will be displayed only when the message receiver active them; 
 *    Public messages can be ideas, articles, or anything else the user wants to express publicly. 
 *    User can track the public messages of a certain address through the client. 
 *    Private messages, group messages, and Keys are encrypted in a manner similar to signal protocol for privacy protection.
 *   
 * The user client: 
 * The clients of KEYS Network include full-node client and user client. 
 * Full nodes, similar to Ethereum's full nodes, are responsible for maintaining the operation of blockchain, 
 * corresponding to user clients' requests for data. In return, full-node operators will receive corresponding incentives. 
 * While the user client, on the one hand, is similar to the light-node. 
 * Normally, it receives the block header and the address list involved in the block transaction from the whole node. 
 * If it finds that the address list has the transaction associated with the user address, 
 * the token owned by the user or the address tracked by the user, it requests the full node for detailed data. 
 * On the other hand, the user client is the data processing terminal, 
 * which decrypts the transaction data obtained from the full-node and displays it to the user. 
 * In addition, when user sends a transaction, the user client will broadcast the transaction to the stored full-node list, 
 * then the full-node will pack it into the blockchain.
 *   
 * At a time the major social apps are free, making people pay for the cost of storaging and transferring their data may not be the way to go. 
 * And a social network built on blockchain would undoubtedly be at a snail's pace, 
 * not suitable for IM applications, more like the message boards Grandpa used in the last century. 
 * Therefore, we must know how many friends need such a shit decentralized social network.
 *   
 * We're trying to launch the first donation for KEYS Network here.
 *   
 * Fundraising target: 2000 ETH
 * Fundraising rules: one address can only donate one share, and each share is 0.01E. 
 * If you donate one share, you will get 10000 KEYS. 
 * Donors can get a refund at any time and will not be able to donate again after a refund.
 * KEYS: The original tokens of KEYS Network, the totalsupply is 5 billion: 
 *     44% for the first donation; 
 *     6%  for awarding the development team after the launch of the mainnet; 
 *     30% for airdrop; 
 *     20% for the community Treasury, which can be used for the subsequent development work, 
 *             can also be used to reward people who have made outstanding contributions to community development, 
 *             of course, how to used is up to the community proposal.
 *
 * Fundraising instructions:
 * Limit one share to one address, 200000 in total. 
 * On the one hand, we hope the donors are authentic users and are willing to pay for such a decentralized social network. 
 * And on the other hand,we hope to spread the initial stakes as far as possible.
 * All donation will be spent on development work. Of course, in decentralized world, 
 * codes are better than words, code is law. To solve the trust problem by codes, 
 * the donation will be kept in the donated contract, and it will be released 20 times, 
 * which means the developer will only be able to extract 1/20 of the donation at one time, 
 * to encourage developers to accelerate development, because the donor can refund from the Treasury when the development is not expected. 
 * Developers' first withdrawal will be limited to 30 days after the contract is deployed. 
 * In the meantime, it is important to note that every withdrawal will produce up to 5 percent loss.
 *   
 * Finally, as a social network, some social fission tricks are necessary. Donations are divided into three forms:
 * 1. Genesis donation:  the top 2,000 donors can be genesis donors. 
 *                       Genesis donors will receive an additional 2000KEYS reward. 
 *                       The address of genesis donors will be referral address, 
 *                       donors who use referral address to donate will get additional KEYS reward, 
 *                       the referral address will also get additional KEYS reward.
 * 2. Referral donation: donors who use referral address to donate will get additional KEYS reward. Reward is tiered.
 *                       NO.2001~20000: the donor and referral address will each receive 1000 KEYS reward.
 *                       NO.20001~60000: the donor and referral address will each receive 750 KEYS reward.
 *                       NO.60001~120000: the donor and referral address will each receive 500 KEYS reward.
 *                       NO.120001~200000: the donor and referral address will each receive 250 KEYS reward.
 *                       Of course, if refunded, the corresponding reward will reset to 0.
 * 3. Common donation: no additional reward.
 *  
 * All rewards will open claim one month before mainnet launch.
 *  
 *  
 * No website for donation, you can only donate in crypto-native ways. Yes, it's fucking stupid.
 * You can call a function on etherscan or directly interact with the contract using hex data.
 *
 * Contract address: this contract
 * Function hexs:
 * 1. genesisdonate: 0x0cb8b3cd
 * 2. donatewithreferral: 0xe401e13c000000000000000000000000+referral address. 
 *                        For example, a referral is 0x1111111111111111111111111111111111111111, 
 *                        then the hex data is 0xe401e13c0000000000000000000000001111111111111111111111111111111111111111
 * 3. donate: 0xf0b1004d
 * 4. refund: 0x1dde2355
 * 5. rewardclaim: 0xa0cd10df
 * 6. withdraw: 0xc10eb14d (only devs)
 *  
 *  
 * ATTENTION, there is no twitter, no discord, no telegram, no any centralized mediums. 
 * All announcements, project progress, codes, or any other information will be updated to the developer address.
 * No plans to announce team information at this moment, it may be released at a moment everyone forgets it. 
 * KEYS Network does not need a god to lead the community.
   
*/




contract KEYS is ERC20{

    event GenesisDonate();
    event Donatewithreferral();
    event Donate();
    event Refund();
    event Withdraw();
    event Claimreward();

    mapping(address => bool)    private _isdonated;
    mapping(address => bool)    private _genesisdonators;
    mapping(address => bool)    private _isrefunded;
    mapping(address => bool)    private _referralrefund;
    mapping(address => address) private _referralship;
    mapping(address => uint256) public  _referralreward;

    uint256 private _withdrawnonce = 0;
    uint256 private _initimestamp;
    address private _devaddress;
    uint256 public  _donatednumbs = 0;
    uint256 public  _genesisnumbs = 0;

    constructor() ERC20("Keys Network Coin", "KEYS") {

        _devaddress = msg.sender;
        _initimestamp = block.timestamp;
        _mint(address(this), 5000000000000000000000000000);
        // KEYS decimals is 18, 5000000000000000000000000000 actually means 5,000,000,000.000000000000000000

    }

    modifier donatecheck {

        require(_donatednumbs < 200000, "Donate is ended");
        require(!_isdonated[msg.sender], "Only donate once");
        require(msg.value == 10000000000000000, "Only allow donate 0.01E");
        // ETH decimals is 18, 10000000000000000 actually means 0.010000000000000000 ETH
        _; 

    }

    function _genesisdonate() public payable donatecheck {

        require(_genesisnumbs < 2000, "Genesis donate is full");

        _transfer(address(this), msg.sender, 10000000000000000000000);  //10,000.000000000000000000
        _referralreward[msg.sender] += 2000000000000000000000;  //2,000.000000000000000000

        _genesisnumbs += 1;
        _donatednumbs += 1;
        _isdonated[msg.sender] = true;

        _genesisdonators[msg.sender] = true;

        emit GenesisDonate();

    }

    function _donatewithreferral(address referral_) public payable donatecheck {

        require(_genesisdonators[referral_], "Referral is wrong");

        _transfer(address(this), msg.sender, 10000000000000000000000);  //10,000.000000000000000000

        if (_donatednumbs < 20000) {
            _referralreward[referral_] += 1000000000000000000000;  
            _referralreward[msg.sender] += 1000000000000000000000;  //1,000.000000000000000000
        }else if (_donatednumbs < 60000) {
            _referralreward[referral_] += 750000000000000000000;  
            _referralreward[msg.sender] += 750000000000000000000;   //750.000000000000000000
        }else if (_donatednumbs < 120000) {
            _referralreward[referral_] += 500000000000000000000;  
            _referralreward[msg.sender] += 500000000000000000000;   //500.000000000000000000
        } else {
            _referralreward[referral_] += 250000000000000000000;  
            _referralreward[msg.sender] += 250000000000000000000;   //250.000000000000000000
        }

        _referralship[msg.sender] = referral_;
        _referralrefund[msg.sender] = true;

        _donatednumbs += 1;
        _isdonated[msg.sender] = true;

        emit Donatewithreferral();

    }

    function _donate() public payable donatecheck {

        _transfer(address(this), msg.sender, 10000000000000000000000);  //10,000.000000000000000000

        _donatednumbs += 1;
        _isdonated[msg.sender] = true;

        emit Donate();

    }

    function _refund() public payable {

        require(block.number <= (_initimestamp + 86400 * 600), "Refund ended");  //86400 seconds = 1 day
        require(!_isrefunded[msg.sender], "Only refund once");
        require(balanceOf(msg.sender) >= 10000000000000000000000, "Insufficient KEYS");  //10,000.000000000000000000

        if(_genesisdonators[msg.sender]) {
           _referralreward[msg.sender] = 0;
           _genesisdonators[msg.sender] = false;
           _genesisnumbs -= 1;
        } else if(_referralrefund[msg.sender]) {
           if (_referralreward[_referralship[msg.sender]] != 0) {
               _referralreward[_referralship[msg.sender]] -= _referralreward[msg.sender];
           }
           _referralreward[msg.sender] = 0;
           _referralrefund[msg.sender] = false;
        }           

        _transfer(msg.sender, address(this), 10000000000000000000000);  //10,000.000000000000000000

        uint256 refundamount = address(this).balance/_donatednumbs;
        payable(msg.sender).transfer(refundamount);

        _donatednumbs -= 1;
        _isrefunded[msg.sender] = true;

        emit Refund();

    }

    function _rewardclaim() external payable {

        require((block.number >= (_initimestamp + 86400 * 600)) && (block.number <= (_initimestamp + 86400 * 630)) , "Not time to claim reward");  //86400 seconds = 1 day

        _transfer(address(this), msg.sender, _referralreward[msg.sender]);
        _referralreward[msg.sender] = 0;

        emit Claimreward();

    }

    function _withdraw() public payable {

        require( msg.sender == _devaddress, "Only devs");
        require(block.number >= (_initimestamp + 86400 * 30 * _withdrawnonce + 86400 * 30), "Withdraw closed");  //86400 seconds = 1 day

        uint256 withdrawamount = address(this).balance/(20-_withdrawnonce);
        payable(_devaddress).transfer(withdrawamount);

        _withdrawnonce += 1;

        emit Withdraw();

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