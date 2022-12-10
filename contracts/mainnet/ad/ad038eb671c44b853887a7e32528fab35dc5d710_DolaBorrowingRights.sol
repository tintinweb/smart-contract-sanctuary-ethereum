/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
@title Dola Borrow Rights
@notice The DolaBorrowRights contract is a non-standard ERC20 token, that gives the right of holders to borrow DOLA at 0% interest.
 As a borrower takes on DOLA debt, their DBR balance will be exhausted at 1 DBR per 1 DOLA borrowed per year.
*/
contract DolaBorrowingRights {

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public _totalSupply;
    address public operator;
    address public pendingOperator;
    uint public totalDueTokensAccrued;
    uint public replenishmentPriceBps;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;
    mapping (address => bool) public minters;
    mapping (address => bool) public markets;
    mapping (address => uint) public debts; // user => debt across all tracked markets
    mapping (address => uint) public dueTokensAccrued; // user => amount of due tokens accrued
    mapping (address => uint) public lastUpdated; // user => last update timestamp

    constructor(
        uint _replenishmentPriceBps,
        string memory _name,
        string memory _symbol,
        address _operator
    ) {
        replenishmentPriceBps = _replenishmentPriceBps;
        name = _name;
        symbol = _symbol;
        operator = _operator;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    modifier onlyOperator {
        require(msg.sender == operator, "ONLY OPERATOR");
        _;
    }
    
    /**
    @notice Sets pending operator of the contract. Operator role must be claimed by the new oprator. Only callable by Operator.
    @param newOperator_ The address of the newOperator
    */
    function setPendingOperator(address newOperator_) public onlyOperator {
        pendingOperator = newOperator_;
    }

    /**
    @notice Sets the replenishment price in basis points. Replenishment price denotes the increase in DOLA debt upon forced replenishments.
     At 10000, the cost of replenishing 1 DBR is 1 DOLA in debt. Only callable by Operator.
    @param newReplenishmentPriceBps_ The new replen
    */
    function setReplenishmentPriceBps(uint newReplenishmentPriceBps_) public onlyOperator {
        require(newReplenishmentPriceBps_ > 0, "replenishment price must be over 0");
        require(newReplenishmentPriceBps_ <= 1_000_000, "Replenishment price cannot exceed 100 DOLA per DBR");
        replenishmentPriceBps = newReplenishmentPriceBps_;
    }
    
    /**
    @notice claims the Operator role if set as pending operator.
    */
    function claimOperator() public {
        require(msg.sender == pendingOperator, "ONLY PENDING OPERATOR");
        operator = pendingOperator;
        pendingOperator = address(0);
        emit ChangeOperator(operator);
    }

    /**
    @notice Add a minter to the set of addresses allowed to mint DBR tokens. Only callable by Operator.
    @param minter_ The address of the new minter.
    */
    function addMinter(address minter_) public onlyOperator {
        minters[minter_] = true;
        emit AddMinter(minter_);
    }

    /**
    @notice Removes a minter from the set of addresses allowe to mint DBR tokens. Only callable by Operator.
    @param minter_ The address to be removed from the minter set.
    */
    function removeMinter(address minter_) public onlyOperator {
        minters[minter_] = false;
        emit RemoveMinter(minter_);
    }
    /**
    @notice Adds a market to the set of active markets. Only callable by Operator.
    @dev markets can be added but cannot be removed. A removed market would result in unrepayable debt for some users.
    @param market_ The address of the new market contract to be added.
    */
    function addMarket(address market_) public onlyOperator {
        markets[market_] = true;
        emit AddMarket(market_);
    }

    /**
    @notice Get the total supply of DBR tokens.
    @dev The total supply is calculated as the difference between total DBR minted and total DBR accrued.
    @return uint representing the total supply of DBR.
    */
    function totalSupply() public view returns (uint) {
        if(totalDueTokensAccrued > _totalSupply) return 0;
        return _totalSupply - totalDueTokensAccrued;
    }

    /**
    @notice Get the DBR balance of an address. Will return 0 if the user has zero DBR or a deficit.
    @dev The balance of a user is calculated as the difference between the user's balance and the user's accrued DBR debt + due DBR debt.
    @param user Address of the user.
    @return uint representing the balance of the user.
    */
    function balanceOf(address user) public view returns (uint) {
        uint debt = debts[user];
        uint accrued = (block.timestamp - lastUpdated[user]) * debt / 365 days;
        if(dueTokensAccrued[user] + accrued > balances[user]) return 0;
        return balances[user] - dueTokensAccrued[user] - accrued;
    }

    /**
    @notice Get the DBR deficit of an address. Will return 0 if th user has zero DBR or more.
    @dev The deficit of a user is calculated as the difference between the user's accrued DBR deb + due DBR debt and their balance.
    @param user Address of the user.
    @return uint representing the deficit of the user.
    */
    function deficitOf(address user) public view returns (uint) {
        uint debt = debts[user];
        uint accrued = (block.timestamp - lastUpdated[user]) * debt / 365 days;
        if(dueTokensAccrued[user] + accrued < balances[user]) return 0;
        return dueTokensAccrued[user] + accrued - balances[user];
    }
    
    /**
    @notice Get the signed DBR balance of an address.
    @dev This function will revert if a user has a balance of more than 2^255-1 DBR
    @param user Address of the user.
    @return Returns a signed int of the user's balance
    */
    function signedBalanceOf(address user) public view returns (int) {
        uint debt = debts[user];
        uint accrued = (block.timestamp - lastUpdated[user]) * debt / 365 days;
        return int(balances[user]) - int(dueTokensAccrued[user]) - int(accrued);
    }

    /**
    @notice Approves spender to spend amount of DBR on behalf of the message sender.
    @param spender Address of the spender to be approved
    @param amount Amount to be approved to spend
    @return Always returns true, will revert if not successful.
    */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
    @notice Transfers amount to address to from message sender.
    @param to The address to transfer to
    @param amount The amount of DBR to transfer
    @return Always returns true, will revert if not successful.
    */
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        unchecked {
            balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
    @notice Transfer amount of DBR  on behalf of address from to address to. Message sender must have a sufficient allowance from the from address.
    @dev Allowance is reduced by the amount transferred.
    @param from Address to transfer from.
    @param to Address to transfer to.
    @param amount Amount of DBR to transfer.
    @return Always returns true, will revert if not successful.
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        require(balanceOf(from) >= amount, "Insufficient balance");
        balances[from] -= amount;
        unchecked {
            balances[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /**
    @notice Permits an address to spend on behalf of another address via a signed message.
    @dev Can be bundled with a transferFrom call, to reduce transaction load on users.
    @param owner Address of the owner permitting the spending
    @param spender Address allowed to spend on behalf of owner.
    @param value Amount to be allowed to spend.
    @param deadline Timestamp after which the signed message is no longer valid.
    @param v The v param of the ECDSA signature
    @param r The r param of the ECDSA signature
    @param s The s param of the ECDSA signature
    */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");
            allowance[recoveredAddress][spender] = value;
        }
        emit Approval(owner, spender, value);
    }

    /**
    @notice Function for invalidating the nonce of a signed message.
    */
    function invalidateNonce() public {
        nonces[msg.sender]++;
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
    @notice Accrue due DBR debt of user
    @dev DBR debt is accrued at a rate of 1 DBR per 1 DOLA of debt per year.
    @param user The address of the user to accrue DBR debt to.
    */
    function accrueDueTokens(address user) public {
        uint debt = debts[user];
        if(lastUpdated[user] == block.timestamp) return;
        uint accrued = (block.timestamp - lastUpdated[user]) * debt / 365 days;
        if(accrued > 0 || lastUpdated[user] == 0){
            dueTokensAccrued[user] += accrued;
            totalDueTokensAccrued += accrued;
            lastUpdated[user] = block.timestamp;
            emit Transfer(user, address(0), accrued);
        }
    }

    /**
    @notice Function to be called by markets when a borrow occurs.
    @dev Accrues due tokens on behalf of the user, before increasing their debt.
    @param user The address of the borrower
    @param additionalDebt The additional amount of DOLA the user is borrowing
    */
    function onBorrow(address user, uint additionalDebt) public {
        require(markets[msg.sender], "Only markets can call onBorrow");
        accrueDueTokens(user);
        require(deficitOf(user) == 0, "DBR Deficit");
        debts[user] += additionalDebt;
    }

    /**
    @notice Function to be called by markets when a repayment occurs.
    @dev Accrues due tokens on behalf of the user, before reducing their debt.
    @param user The address of the borrower having their debt repaid
    @param repaidDebt The amount of DOLA repaid
    */
    function onRepay(address user, uint repaidDebt) public {
        require(markets[msg.sender], "Only markets can call onRepay");
        accrueDueTokens(user);
        debts[user] -= repaidDebt;
    }

    /**
    @notice Function to be called by markets when a force replenish occurs. This function can only be called if the user has a DBR deficit.
    @dev Accrues due tokens on behalf of the user, before increasing their debt by the replenishment price and minting them new DBR.
    @param user The user to be force replenished.
    @param amount The amount of DBR the user will be force replenished.
    */
    function onForceReplenish(address user, address replenisher, uint amount, uint replenisherReward) public {
        require(markets[msg.sender], "Only markets can call onForceReplenish");
        uint deficit = deficitOf(user);
        require(deficit > 0, "No deficit");
        require(deficit >= amount, "Amount > deficit");
        uint replenishmentCost = amount * replenishmentPriceBps / 10000;
        accrueDueTokens(user);
        debts[user] += replenishmentCost;
        _mint(user, amount);
        emit ForceReplenish(user, replenisher, msg.sender, amount, replenishmentCost, replenisherReward);
    }

    /**
    @notice Function for burning DBR from message sender, reducing supply.
    @param amount Amount to be burned
    */
    function burn(uint amount) public {
        _burn(msg.sender, amount);
    }

    /**
    @notice Function for minting new DBR, increasing supply. Only callable by minters and the operator.
    @param to Address to mint DBR to.
    @param amount Amount of DBR to mint.
    */
    function mint(address to, uint amount) public {
        require(minters[msg.sender] == true || msg.sender == operator, "ONLY MINTERS OR OPERATOR");
        _mint(to, amount);
    }

    /**
    @notice Internal function for minting DBR.
    @param to Address to mint DBR to.
    @param amount Amount of DBR to mint.
    */
    function _mint(address to, uint256 amount) internal virtual {
        _totalSupply += amount;
        unchecked {
            balances[to] += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    /**
    @notice Internal function for burning DBR.
    @param from Address to burn DBR from.
    @param amount Amount of DBR to be burned.
    */
    function _burn(address from, uint256 amount) internal virtual {
        require(balanceOf(from) >= amount, "Insufficient balance");
        balances[from] -= amount;
        unchecked {
            _totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event AddMinter(address indexed minter);
    event RemoveMinter(address indexed minter);
    event AddMarket(address indexed market);
    event ChangeOperator(address indexed newOperator);
    event ForceReplenish(address indexed account, address indexed replenisher, address indexed market, uint deficit, uint replenishmentCost, uint replenisherReward);

}