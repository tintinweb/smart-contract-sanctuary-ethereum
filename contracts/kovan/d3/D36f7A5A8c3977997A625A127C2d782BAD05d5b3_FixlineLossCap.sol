// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FixlineToken.sol";
import "./FixlineCaps.sol";

interface IPool {
	function notifyReward() external payable; 
}

contract FixlineLossCap {
    //Storage

	//int32 tokenCoef = 100;          // amount of CAPs you gain after resolve
	int32 baseRepMinus = 5; 		
	int32 baseRepPlus = 10; 	
    uint256 public maxSpots = 16;
	uint256 public minbet = 1000000000000;			//0.000001eth		//16 finney; //0.016 eth
	uint256 public maxbet = 100000000000000000000;		//100eth
	uint256 capDiv = 1;
	uint256 fxlDiv = 1;
	uint256 lossDiv = 5; 								// looser gets 5% of the total bet
	uint256 winDiv = 90;								// winner gets 90% of the total bet
	uint256 adminDiv = 3;								// admin gets 3% of the total bet
	uint256 public accumulatedCapsFees;                 // 1% to all CAPs stakers
	uint256 public accumulatedFxlFees;                  // 1% to FXL

	address payable fixlineTokenAddress;
	FixlineToken FXL;
	address payable capsTokenAddress;
	FixlineCaps FXC;
	address fixlinewallet;
	address public admin;

	address public CAPs_staking_Pool_address;

	mapping(uint256 => address) public maker;  // betId to maker's address
    mapping(uint256 => mapping(uint256 => address)) public takers;   // betId to spotsTaken to taker's address
           

	mapping(uint256 => uint256) public spots;                // betIds to created spots
    mapping(uint256 => uint256) public spotsTaken;    // betId to spotsTaken
    mapping(address => mapping(uint256 => uint256)) public takerSpot;
    mapping(uint256 => uint256) public amount;        // betId to amount
	mapping(uint256 => uint256) public expireTime;    // betId to bet expiry time
    mapping(address => uint256) public balances;      // address to balance
	mapping(address => uint256) public makerDepositedBalance;
	mapping(address => int256) public reputation;        // address to repuration score
	//mapping(uint256 => uint256) public toWinAmt;
	//mapping(address => uint256) public resolvedBets;  // address to resolved bets
	//mapping(address => uint256) public totalBets;     // address to created bets
    

    constructor() {
        fixlinewallet = msg.sender;
        admin = msg.sender;
    }

    function setCAPsPoolAddress(address CAPs_Staking_Pool) public {
		CAPs_staking_Pool_address = CAPs_Staking_Pool;
	}

    function SetFXL(address payable fxl) public{
        require(msg.sender == admin, "Sender is not the admin.");
        FXL = FixlineToken(fxl);
        fixlineTokenAddress = fxl;
    }
	
    function SetFXC(address payable fxc) public{
        require(msg.sender == admin, "Sender is not the admin.");
        FXC = FixlineCaps(fxc);
        capsTokenAddress = fxc;																																						
    }


    //Methods
    /**
     *@dev max bet prevents int32 cast overflow 

	 DepositAndMakeBothSidesBet : Allows users to create a bet
      
	  PARAMS --
	  betAmt : The amount that the maker has to deposit for bet creation.
	  numSpots : number of bet takers
	  betID : randomly generated betID
	  apiID : checks the matches
	  expiry : bet expiry time
	  fave : true/false -- against the match or in favor

    */



	function DepositAndMakeBothSidesBet(uint32 apiID, uint256 betID, bool fave, uint256 betAmt, uint256 numSpots, uint256 expiry) public payable {

		require(msg.value >= (betAmt * numSpots) , "Bet maker has to put some ether.");
		require(numSpots <= maxSpots, "Too many spots");
		//require(msg.value >= minbet && msg.value <= maxbet, "Put correct amount.");

		makerDepositedBalance[msg.sender] += msg.value;

		maker[betID] = msg.sender;
		amount[betID] = betAmt;
		spots[betID] = numSpots;
		expireTime[betID] = expiry;
		//toWinAmt[betID] = betAmt;

		int256 slots = int256(numSpots);	
		reputation[msg.sender] -= baseRepMinus*slots;

		//FXL.safeTransfer(msg.sender, amount);
		emit BetMade(apiID, fave, msg.sender, betID, betAmt/2, numSpots, expireTime[betID], block.timestamp);
	}



    function DepositAndTakeBets(uint256[] memory betIDs) public payable {   // Allows users to take the bet
		
		require(betIDs.length <= maxSpots, "Too many bets taken");
		require(msg.value != 0, "Bet taker has to put some ether.");
		//balances[msg.sender] += msg.value;

        //check if user sent enough money
        for(uint256 i = 0; i < betIDs.length; i++) {

            require(maker[betIDs[i]] != address(0), "Invalid betID");
		    //require(balances[maker[betIDs[i]]] >= amount[betIDs[i]], "Insufficient maker funds");
		    //require(balances[msg.sender] >= toWinAmt[betIDs[i]], "Insufficient taker funds");
		    require(block.timestamp < expireTime[betIDs[i]], "Bet expired");
		    require(spotsTaken[betIDs[i]] < spots[betIDs[i]], "All spots already filled");
		    
		    //balances[maker[betIDs[i]]] -=  amount[betIDs[i]];
		    //balances[msg.sender] -= toWinAmt[betIDs[i]];

		 	reputation[msg.sender] -= baseRepMinus;
		    
            takerSpot[msg.sender][betIDs[i]] = spotsTaken[betIDs[i]];
			takers[betIDs[i]][spotsTaken[betIDs[i]]] = msg.sender;
            spotsTaken[betIDs[i]] += 1;
			        
        }
        emit BetsTaken(msg.sender, betIDs);
    }

	function checkBalance() public view returns(uint256) {
		return address(this).balance;
	}


	function claimByAdmin(uint256[] memory betIds, address[] memory lossers) public {   //Allows admin to claim if the lossers have not claimed
		require(msg.sender == admin, "You are not the admin");
		require(betIds.length == lossers.length, "Number of betIds and addresses should be equal");

		for(uint i = 0; i < betIds.length && i <= lossers.length; i++){
			if(maker[betIds[i]] == lossers[i]) {
				MakerClaimLoss(betIds[i], lossers[i]);
			}
			else {
				TakerClaimLoss(betIds[i], lossers[i]);
			}
		}
	}

    
	function ClaimBatch(uint256[] memory betIds) public {     // Allow lossers to claimLoss
		for(uint256 i = 0; i < betIds.length; i++) {
			if(maker[betIds[i]] == msg.sender){ 
				MakerClaimLoss(betIds[i], msg.sender); 
			}	else { 
				TakerClaimLoss(betIds[i], msg.sender); 
			}
		}
	}


    function MakerClaimLoss(uint256 betID, address  m) private {

		for(uint256 i = 0; i < spotsTaken[betID]; i++) {
		    if(takers[betID][i] != address(0)){
		      	balances[takers[betID][i]] += ((amount[betID] * 2 * winDiv) / 100) ;		// Winner gets 90% after claiming looser claims LOSS
				balances[m] += ((amount[betID] * 2 * lossDiv) / 100);						// looser claims 5% after claiming LOSS
				balances[admin] += ((amount[betID] * 2 * adminDiv) / 100);					// admin gets 3% of the total bet
			
				accumulatedCapsFees += ((amount[betID] * 2 * capDiv) / 100);					// 1% of the total bet
				accumulatedFxlFees += ((amount[betID] * 2 * fxlDiv) / 100);						// 1% of the total bet

				IPool(CAPs_staking_Pool_address).notifyReward{value : accumulatedCapsFees}();// Transfer accumulatedCapsFees to staking contract
				accumulatedCapsFees = 0;

				reputation[takers[betID][i]] += baseRepPlus;
				reputation[m] += baseRepPlus;
		    }
		}

		// TRANSFER ETHER to FXL contract addresses
		payable(fixlineTokenAddress).transfer((amount[betID] * 2 * fxlDiv) / 100);
		accumulatedFxlFees = 0;

		FXL.mintYield(1* 10 ** 18);
		FXC.mintYield(msg.sender, 1 * 10 ** 18);

		delete maker[betID];
		emit MakerLossClaimed(m, betID);
    }

    
    function TakerClaimLoss(uint256 betID, address t) private {

		bool isTaker;
		for(uint256 i = 0; i < spotsTaken[betID]; i++) {
			if(takers[betID][i] == t){
				isTaker = true;
			}
		}

        require(isTaker, "Sender is not taker, or already claimed loss");
		balances[maker[betID]] += ((amount[betID] * 2 * winDiv) / 100) ;				// Winner gets 90% after claiming looser claims LOSS
		balances[t] += ((amount[betID] * 2 * lossDiv) / 100) ;							// looser claims 5% after claiming LOSS
		balances[admin] += ((amount[betID] * 2 * adminDiv) / 100);						// admin gets 3% of the total bet
			
		accumulatedCapsFees += ((amount[betID] * 2 * capDiv) / 100);					    // 1% of the total bet
		accumulatedFxlFees += ((amount[betID] * 2 * fxlDiv) / 100);							// 1% of the total bet

		IPool(CAPs_staking_Pool_address).notifyReward{value : accumulatedCapsFees}();    // Transfer accumulatedCapsFees to staking contract
		accumulatedCapsFees = 0;


		reputation[t] += baseRepPlus;
		reputation[maker[betID]] += baseRepPlus;		
		
		
		// TRANSFER ETHER to FXL contract addresses
		payable(fixlineTokenAddress).transfer((amount[betID] * 2 * fxlDiv)/100);
		accumulatedFxlFees = 0;


		FXL.mintYield(1* 10 ** 18);
		FXC.mintYield(msg.sender, 1 * 10 ** 18);

		delete takers[betID][takerSpot[t][betID]];
		emit LossClaimed(msg.sender, betID);
    }


    function Deposit() public payable {
        balances[msg.sender] += msg.value;
    }


	function Withdraw(uint256 amt) public {
	   
		require(amt <= balances[msg.sender], "Withdrawl amt is more than balance.");
		payable(msg.sender).transfer(amt);
		balances[msg.sender] -= amt;			                 // update balance of msg.sender after withdrawl
		emit Withdrawn(msg.sender, balances[msg.sender]);
	}


	function creditMyProfile(uint256[] memory betIds) public {   //Transfers amount to maker is no. of takers is less than the selected spot
		for(uint i=0; i < betIds.length; i++) {
			//require(spotsTaken[betIds[i]] < spots[betIds[i]], "Spots are filled");
			require(msg.sender == maker[betIds[i]], "You are not the maker of the bet");
			balances[msg.sender] = (makerDepositedBalance[maker[betIds[i]]] - (amount[betIds[i]] * spotsTaken[betIds[i]]));
			int256 rep = int256(spots[betIds[i]] - spotsTaken[betIds[i]]);
			reputation[msg.sender] += baseRepMinus * rep;
		}
	}


	function Cancel(uint256 betID) public{                       // Allow makers to cancel the bet
		require(msg.sender == maker[betID], "msg.sender is not the maker of the bet.");
		require(spotsTaken[betID] == 0, "Bets has been taken.");  //you can only cancel untaken bets
		maker[betID] = address(0);
		delete betID;
		//balances[msg.sender] += amount[betID];
		balances[msg.sender] += makerDepositedBalance[msg.sender];
		reputation[msg.sender] += baseRepMinus;
		emit Cancelled(betID);
	}

	
	function SetFixlineWallet(address newFixlineWallet) public {
	    require(msg.sender == fixlinewallet, "Msg.sender is not the current fixlinewallet address.");
	    fixlinewallet = newFixlineWallet;
	}
	
	function SetAdmin(address newAdmin) public {
	    require(msg.sender == admin, "Msg.sender is not the admin");
	    admin = newAdmin;
	}
	

	function updateMaxbet(uint256 newMaxbet) public {
		require(msg.sender == admin, "Msg.sender is not the admin");
		maxbet = newMaxbet;
	}

	function updateMinbet(uint256 newMinbet) public {
		require(msg.sender == admin, "Msg.sender is not the admin");
		minbet = newMinbet;
	}

	event BetMade(uint32 indexed apiID, bool fave, address indexed creator, uint256 indexed betID, uint256 betAmtPerSpot, uint256 spots, uint256 expireTime, uint256 createdTime);
    event BetsTaken(address indexed taker, uint256[] betIDs);
    event LossClaimed(address indexed claimer, uint256 indexed betID);
	event MakerLossClaimed(address indexed claimer, uint256 indexed betID);
	event Cancelled(uint256 indexed betID);
	event Withdrawn(address indexed payee, uint256 indexed amt);
	
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FixlineLossCap.sol";


contract FixlineToken is ERC20 {
    address FLCa;
    FixlineLossCap FLC;
    address creator;
    uint256 public initialSupply = 100000000;  // 100M
    uint256 public supplyCap = 24000000;       // 24M
    uint256 public tokenPrice;    //1 finney;
    //uint256 balFac = 1000000000; //1 bil
    
    constructor(uint256 supply) ERC20("FixlineToken", "FXL") {
        _mint(msg.sender, supply);
        creator = msg.sender;
    }
    
    function transfer(address to, uint256 amt) public override returns(bool){
        _transfer(msg.sender, to, amt);
        emit Transfer(msg.sender, to, amt);
        return true;
    }
    
    function setFLC(address a) public{
        require(msg.sender == creator);
        FLCa = a;
        FLC = FixlineLossCap(a);
    }

    function mintYield(uint256 numTokens) public payable {
        require(msg.sender == FLCa);
        _mint(payable(address(this)), numTokens);
    }

    function burnToken(uint256 numTokens) public {
        require(msg.sender == FLCa);
        _burn(msg.sender, numTokens);
    }

    function checkBalanceOfContract() public view returns(uint256) {
        return address(this).balance;
    }


    function Purchase(uint256 numTokens) public payable {
        require(msg.value == numTokens * tokenPrice);
        _transfer(creator, msg.sender, numTokens);
    }

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FixlineLossCap.sol";


contract FixlineCaps is ERC20 {

    address creator;
    address FLCa;    //fixlinelosscap
    FixlineLossCap FLC;
    //uint256 initialSupply;
    //uint256 capFac = 1000000000; //1 bil
    

    constructor() ERC20("CapsToken", "CAPS") {
        _mint(msg.sender, 0);
        creator = msg.sender;
    }

    
    function setFLC(address a) public {
        require(msg.sender == creator);
        FLCa = a;
        FLC = FixlineLossCap(a);
    }
    
    function transfer(address to, uint256 amt) public override returns(bool){
        _transfer(msg.sender, to, amt);
        emit Transfer(msg.sender, to, amt);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function mintYield(address a, uint256 numTokens) public{
        require(msg.sender == FLCa);
        _mint(a, numTokens);
    }

    
    function burn(uint256 numTokens) public {
        require(msg.sender == FLCa);
        _burn(msg.sender, numTokens);
    }


    receive() external payable {}
    fallback() external payable {}
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