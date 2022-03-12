/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

pragma solidity 0.6.7;

contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

abstract contract DSTokenLike {
    function totalSupply() virtual public view returns (uint256);
    function mint(address, uint256) virtual public;
    function transfer(address, uint256) virtual public;
}

contract FixedProtocolTokenMinter is GebMath {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "FixedProtocolTokenMinter/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Initial amount to mint per week before long term inflation kicks in
    uint256 public initialAmountToMintPerWeek;                            // wad
    // Last timestamp when the contract accrued inflation
    uint256 public lastWeeklyMint;                                        // timestamp
    // Last week number when a new terminal year started
    uint256 public lastTerminalYearStart;
    // Token supply recorded at the start of a terminal year
    uint256 public terminalYearStartTokenAmount;
    // Last week number when the contract accrued inflation
    uint256 public lastTaggedWeek;
    // Timestamp when initial minting starts
    uint256 public mintStartTime;
    // Whether minting is currently allowed
    uint256 public mintAllowed  = 1;

    uint256 public constant WEEK                     = 1 weeks;
    uint256 public constant WEEKS_IN_YEAR            = 52;
    uint256 public constant INITIAL_INFLATION_PERIOD = WEEKS_IN_YEAR * 1; // 1 year
    uint256 public constant TERMINAL_INFLATION       = 2;                 // 2% compounded weekly

    // Address that receives minted tokens during the initial mint period
    address     public initialMintReceiver;
    // Address that receives minted tokens during the initial mint period
    address     public terminalMintReceiver;

    // The token being minted
    DSTokenLike public protocolToken;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Mint(uint256 weeklyAmount);
    event ModifyParameters(bytes32 parameter, address data);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event SwitchedToTerminal();

    constructor(
      address initialMintReceiver_,
      address terminalMintReceiver_,
      address protocolToken_,
      uint256 mintStartTime_,
      uint256 initialAmountToMintPerWeek_
    ) public {
        require(initialMintReceiver_ != address(0), "FixedProtocolTokenMinter/null-initial-mint-receiver");
        require(terminalMintReceiver_ != address(0), "FixedProtocolTokenMinter/null-terminal-mint-receiver");
        require(protocolToken_ != address(0), "FixedProtocolTokenMinter/null-prot-token");

        require(mintStartTime_ > now, "FixedProtocolTokenMinter/invalid-start-time");
        require(initialAmountToMintPerWeek_ > 0, "FixedProtocolTokenMinter/null-initial-amount-to-mint");

        authorizedAccounts[msg.sender] = 1;

        initialMintReceiver        = initialMintReceiver_;
        terminalMintReceiver       = terminalMintReceiver_;
        protocolToken              = DSTokenLike(protocolToken_);
        mintStartTime              = mintStartTime_;
        initialAmountToMintPerWeek = initialAmountToMintPerWeek_;

        emit AddAuthorization(msg.sender);
    }

    // --- Administration ---
    /*
    * @notify Change the initialMintReceiver
    * @param parameter The parameter name
    * @param data The new address for the receiver
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "initialMintReceiver") {
          initialMintReceiver = data;
        }
        else revert("FixedProtocolTokenMinter/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Change mintAllowed
    * @param parameter The parameter name
    * @param data The new value for mintAllowed
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "mintAllowed") {
          mintAllowed = data;
        }
        else revert("FixedProtocolTokenMinter/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Manually switch to terminal inflation
    */
    function switchToTerminal() external isAuthorized {
        require(lastTaggedWeek < INITIAL_INFLATION_PERIOD, "FixedProtocolTokenMinter/already-terminal");
        lastWeeklyMint               = now;
        lastTaggedWeek               = INITIAL_INFLATION_PERIOD;
        lastTerminalYearStart        = INITIAL_INFLATION_PERIOD;
        terminalYearStartTokenAmount = protocolToken.totalSupply();
        emit SwitchedToTerminal();
    }

    // --- Core Logic ---
    /*
    * @notice Mint tokens for this contract
    */
    function mint() external {
        require(now > mintStartTime, "FixedProtocolTokenMinter/too-early");
        require(mintAllowed == 1, "FixedProtocolTokenMinter/mint-not-allowed");
        require(addition(lastWeeklyMint, WEEK) <= now, "FixedProtocolTokenMinter/week-not-elapsed");

        uint256 weeklyAmount;
        lastWeeklyMint = (lastWeeklyMint == 0) ? now : addition(lastWeeklyMint, WEEK);

        if (lastTaggedWeek < INITIAL_INFLATION_PERIOD) {
          weeklyAmount = initialAmountToMintPerWeek;
        } else {
          weeklyAmount = multiply(terminalYearStartTokenAmount, TERMINAL_INFLATION) / 100 / WEEKS_IN_YEAR;
        }

        lastTaggedWeek = addition(lastTaggedWeek, 1);
        protocolToken.mint(address(this), weeklyAmount);

        if (subtract(lastTaggedWeek, lastTerminalYearStart) >= WEEKS_IN_YEAR) {
          lastTerminalYearStart        = lastTaggedWeek;
          terminalYearStartTokenAmount = protocolToken.totalSupply();
        }

        emit Mint(weeklyAmount);
    }

    /*
    * @notice Transfer minted tokens
    * @param amount The amount to transfer
    */
    function transferMintedAmount(uint256 amount) external isAuthorized {
        address tokenReceiver = (lastTaggedWeek > INITIAL_INFLATION_PERIOD) ? terminalMintReceiver : initialMintReceiver;
        protocolToken.transfer(tokenReceiver, amount);
    }
}