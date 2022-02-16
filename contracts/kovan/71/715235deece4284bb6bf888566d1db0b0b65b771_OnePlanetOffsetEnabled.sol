/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity >=0.6.0;

/*
                                                    ./>.
                                    .<.           ./>>>>>.            .-
                                    (>>>>><....<>>>>>>>>>>>>><...><>>>>>
                                   (>>>>>>>>===   ........   ====>>>>>>>>
                                 ./>>>== ..<>>>==============>>>>>. ==>>>>>
                              .<>>=  (>>==                        ==>>>. =\>><.
                      (>>>>>>>>= ./>=       ..<>>>>>>>>>>>>>>>>..      =\>< =\>>>>>>>>
                      (>>>>>= ./>=     .<>>>>>>>>>>>>>>>>>>>>>>>>>>>>.    =\>> =\>>>>=
                      (>>>= </=-    <>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.    =\> =\>>>
                     ./>= (/=    (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.   =\> =\>+
                    (/= (/=    (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+   =\> (>>
                 .<>>= (=    (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.   (> (\>>.
            (>>>>>>/ ./=   ./>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   (\-.(>>>>>>+
             (\>>>>=./=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=   =>>>>>>>>>>>.  =\> (>>>>=
              (>>>=./=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=       \>>>>>>>>>>-  (\>.\>>=
               (>= (=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>          \>>>>>>>>>>   (> (>>
               (>-(/   ./>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=            (>>>>>>>>>>   (> (>
              (>= (=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=     .<>>     (>>>>>>>>>>  (> (>>
             (>>= /=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=     (>====>>    (>>>>>>>>>   (> (>>.
          ./>>>>-(>   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=    .<========>.   (>>>>>>>>   (> (>>>>.
         =\>>>>>-(>   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=     />==========>>   =>>>>>>>   (= (>>>>>=
            =>>>-(>   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=    .>=====<<<<<<===>.   \>>>>>   (= (>>=
              (>) (>   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>=    .>=====(<<<<<<<<</==>.  =\>>=  (/=(>>=
               (> (>   (>>>>>>>>>>>>>>>>>>>>>>>>>=.    .>====\(<<<<<<<<<<<<</==>.  ==-  (/ (>=
               (>=(\=   (>>>>>>>>>>>>>>>>>>>==      .<>====\/<<<<<<<<<<<<<<<<<</=>>.    /=(/>
               (>> (>   (>>>>>>>>>>>====        ./>>====\<<<<<<<<<<<<<<<<<<<<<<<<</=   (= (>>
              (>>>> (>                   ...<>>>====\<<<<<<<<<<<<<<<<<<<<<<<<<<<<</   (> (>>>\
             (>>>>>> (>    ..../<<<>==========\\<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   (= (>>>>>>
              ===>>>> (>.   ======<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=  ./= (>>>===
                   =\>.=\>   =\<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   (/= (>=
                     (>> (\<   =\<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   ./= (//
                      (>>> (>>   =<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   ./= ./>>
                      (>>>>< =\>.    =<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   .</=../>>>=
                      (>>>>>>>. =>>.    ==<<<<<<<<<<<<<<<<<<<<<<<<==    .<>= .<>>>>>>>
                      (======>>>>. =\>>.      ====<<<<<<<<=====     .<>>= .(>>>=======
                                =\>>>. ==>>>>..              ...<>>== ..>>>=
                                  (>>>>>>>... =====>>>>>>======...<>>>>>>=
                                   (\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=
                                    (>==         =>>>>>>>>==       .==>=
                                                   =\>>>=
                                                     ==
                                                     
     
             ▄▄▄▄     ▄▄▄▄▄▄▄▄▄▄▄  ▄▄           ▄▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄
             ████     ██▀▀▀▀▀▀▀██  ██           ███▀▀▀▀████  ▐██▀▀▀▀▀▀██▌  ██▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀██▀▀▀▀
               ██     ███████████  ██           ███████████  ▐██      ██▌  ███████████       ██
               ██     ████         ██           ██▌    ████  ▐████    ██▌  ████              ████
               ██     ████         ███████████  ██▌    ████  ▐████    ██▌  ████              ████
           ████████▌  ████         ███████████  ███    ████  ▐████    ██▌  ███████████       ████
*/


// ---------------------------------------------------------------------------------------------------------------
// '1PLCO2' token contract
//  1PLCO2 is a tokenized Carbon Credit.
//  1PLCO2 = 1 Carbon Credit = 1 metric ton of CO2
//  This 1PLANET contract also offers direct offsetting functions for dApps and Smart Contracts such as NFT minting.
//  When 1PLCO2 is burned/retired then carbon credits are also permenantly burned/retired for carbon offsetting.
//  Use the dApp at www.1PLANET.app for verification and see www.climatefutures.io for more information.
//------------------------------------------------------------------------------------------------------------------

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
    

abstract contract DAIpaymentInterface {
    
     function balanceOf(address _owner) public view virtual returns (uint256 balance);
     function approve(address usr, uint wad) external virtual returns (bool);
     function transferFrom(address spender, address dst, uint wad) public virtual returns (bool);
     function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
}


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0xacCeB894DbA9632E49C56bC0ED75e515aeA95a12;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

abstract contract OnePlanetInterface {
// DO NOT MODIFY FUNCTION NAMES WITHOUT CHECKING THE NETWORK 1PLANET CONTRACT     
     function balanceOf(address _owner) public view virtual returns (uint256 balance);
     function retire1PLCO2(uint tokens, string memory message) public virtual returns (bool success);
     function transfer(address to, uint tokens) public virtual returns (bool success);
     function removePermanently(address account, uint256 amount) public virtual returns (bool success);
     function approve(address spender, uint tokens) public virtual returns (bool success);
     function approveAndOffset(address spender, uint tokens) public virtual returns (bool success); 
}

abstract contract OnePlanetConnected {
    //OnePlanet State Variables
    address public OnePlanetAddress;      
    uint256 public CO2drawdown; // a fixed extra amount of CO2 to be offset by a Tx. Default is zero. Creates a more carbon negative Tx, i.e. carbon drawdown.
    uint256 public CO2drawdownMultiplier; // a drawdown multiplier for a Tx. Default is 1. Creates a more carbon negative Tx, i.e. carbon drawdown.
	string public offsetMsg;
	uint8 public offsetSwitch; // used to turn off or on the automated offsetting function. ON = 1;

constructor() public {
        //OnePlanet Carbon Offset Settings
        OnePlanetAddress = 0x665caadf8C1B1863ABd3dBb1EA8296cd7D0b8106;  // OnePlanet contract address
        offsetSwitch = 1;
        offsetMsg = "This NFT is minted climate friendly using 1PLANET! Visit www.1PLANET.app to verify the Tx metadata. Burning one 1PLCO2 offsets 1 metric ton of CO2.";
        CO2drawdown = 1e17;             // equals 0.1 tons of 1PLCO2
        CO2drawdownMultiplier = 1;
    }
   //OnePlanet Modifiers
    modifier OnePlanetOffset {                    
        
        OnePlanetInterface OnePlanetInstance = OnePlanetInterface(OnePlanetAddress);
        
        if(offsetSwitch == 1 && OnePlanetInstance.balanceOf(address(this)) >= 1e17){
        
            offsetWith1PLCO2();
            _;
        } else {
            
            walletOffset1PLCO2();
            _;
        }

     }
    
     function offsetWith1PLCO2() internal {
        OnePlanetInterface OnePlanetInstance = OnePlanetInterface(OnePlanetAddress);
   
        uint256 CO2offset = (CO2drawdown * CO2drawdownMultiplier) / 100; // since Polygon is PoS network we can offset a fixed amount and not estimate gas usage etc.

        require(OnePlanetInstance.balanceOf(address(this)) >= CO2offset, "Not enough 1PLCO2 tokens to retire"); //Require that the NFT minter has enough 1PLANET tokens
        
        OnePlanetInstance.retire1PLCO2(CO2offset, offsetMsg); //Retire 1Planet tokens based on CO2 emitted
        }

    function walletOffset1PLCO2() internal {
        OnePlanetInterface OnePlanetInstance = OnePlanetInterface(OnePlanetAddress);
   
        uint256 CO2offset = (CO2drawdown * CO2drawdownMultiplier) / 100; // since Polygon is PoS network we can offset a fixed amount and not estimate gas usage etc.

        require(OnePlanetInstance.balanceOf(address(msg.sender)) >= CO2offset, "Not enough 1PLCO2 tokens to retire"); //Require that the NFT minter has enough 1PLANET tokens

        OnePlanetInstance.approveAndOffset(address(this), CO2offset);
        
        OnePlanetInstance.removePermanently(msg.sender, CO2offset); //Retire 1Planet tokens based on CO2 emitted
        }
    

    function topUpBalance() public payable {}               // maybe remove?

    //OnePlanet Owner Functions
    function setOffsetSwitch(uint8 offsetSwitchState) external {
        offsetSwitch = offsetSwitchState;
    }

    function updateOffsetMsg(string calldata message) external {
        offsetMsg = message;
    }
    
    function update1PLANETaddress(address payable new1PLANETaddress) external {
        OnePlanetAddress = new1PLANETaddress;
	}
    // extra offset value should be in long integer format 1e18
    function updateCO2drawdown(uint256 longInteger) external {
        CO2drawdown = longInteger;
    }

    // when updating this multiplier value: 100 = 1.00, 155 = 1.55, 200 = 2.00 etc
    function updateDrawdownMultiplier (uint256 threeDigitMultiplier) external {
        CO2drawdownMultiplier = threeDigitMultiplier;
    }

    

}
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract OnePlanetOffsetEnabled is ERC20Interface, Owned, SafeMath, OnePlanetConnected {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startDate;
    uint public endDate;
    uint public _maxSupply;
    uint public updateInterval;
    uint public currentIntervalRound;
    AggregatorV3Interface internal priceFeed;
    uint public ethPrice;
    uint public ethAmount;
    uint public ethPrice1PL;
    uint public SigDigits;
    uint public offsetSigDigits;
    uint public tokenPrice;
	address payable public oracleAddress;
	address payable public daiAddress;
	address public retireAddress;
	uint256 public gasCO2factor;
	uint256 public CO2factor1; // for future use cases
	uint256 public CO2factor2;
	uint256 public CO2factor3;
	uint256 public CO2factor4;
	uint256 public CO2factor5;
	uint256 public gasEst;
    event CarbonOffset(string message);
    event ApprovedDaiPurchase(address buyer, uint256 ApprovedAmount, bool success, bytes data);
    event Deposit(address indexed sender, uint value);
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "1PLCO2";
        name = "1PLANET Carbon Credit";
        decimals = 18;
        SigDigits = 100;
        offsetSigDigits = 1e15; // to 1 kg CO2
        tokenPrice = 1000;
        updateInterval = 1;
        endDate = now + 2000 weeks;
        _maxSupply = 150000000000000000000000000; // 150M tokens maximum supply = 150M metric tons CO2e
		oracleAddress = 0x9326BFA02ADD2366b30bacB125260Af641031331;
		retireAddress = 0x0000000000000000000000000000000000000000;
		daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; // Kovan address only
		priceFeed = AggregatorV3Interface(oracleAddress);
        gasCO2factor = 380000000000;
    }
    

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
	
    function maxSupply() public view returns (uint) {
        return _maxSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override OnePlanetOffset returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public OnePlanetOffset override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndOffset(address spender, uint tokens) public returns (bool success) {
        allowed[tx.origin][spender] = tokens;
        emit Approval(tx.origin, spender, tokens);
        return true;
        
    }

    // ------------------------------------------------------------------------
    // Send ETH to get 1PLCO2 tokens
    // ------------------------------------------------------------------------
    receive() external payable OnePlanetOffset {
        require(now >= startDate && now <= endDate);
        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        emit Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
        currentIntervalRound = safeAdd(currentIntervalRound, 1);
        if(currentIntervalRound == updateInterval) {
            getLatestPrice();
            currentIntervalRound = 0;
        }
    
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 temp = safeMul(weiAmount, ethPrice);
        temp = safeDiv(temp, SigDigits);
        temp = safeDiv(temp, tokenPrice);
        temp = safeMul(temp, 100);
        return temp;
    }
    
    
    //-------------------------------------------------------------------------------------------
    // Enables user to purchase 1PLCO2 carbon credits with DAI stable coins
    // Buyer must first APPROVE the DAI amount transfer directly with the DAI contract
    // Address on Kovan: 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
    //-------------------------------------------------------------------------------------------
    function buy1PLwithDai(uint256 daiAmount) public OnePlanetOffset returns (bool success) {
        
        DAIpaymentInterface DAIpaymentInstance = DAIpaymentInterface(daiAddress);
        
        require(daiAmount > 0, "You need to send at least some DAI");
        require(DAIpaymentInstance.balanceOf(address(msg.sender)) >= daiAmount, "Not enough DAI");
        uint256 daiAllowance = DAIpaymentInstance.allowance(msg.sender, address(this));
        require(daiAllowance >= daiAmount, "You need to approve more DAI to be spent");
        
        uint256 tokens = safeDiv(daiAmount, tokenPrice);
        tokens = safeMul(tokens, 100);
        
        DAIpaymentInstance.transferFrom(msg.sender, address(this), daiAmount);
        
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }
    
    //-------------------------------------------------------------------------------------------
    // Enables dApps to perform carbon offsetting applications with 1PLCO2 carbon credits
    // Can be used by third-party developers and it will log custom messages
    // Verify transaction details at www.1PLANET.app
    //-------------------------------------------------------------------------------------------
    function retireOnePL(uint tokens, string calldata message) external returns (bool success) {
        require(tokens > offsetSigDigits, "Retire at least 0.001 (1kg) 1PLCO2");
        tokens = safeDiv(tokens, offsetSigDigits);
        tokens = safeMul(tokens, offsetSigDigits); // retire in kg
        transfer(retireAddress, tokens);
        emit CarbonOffset(message);
        return true;
    }
    
    //-------------------------------------------------------------------------------------------
    // Enables dApps to perform carbon offsetting applications with ETH
    // Users pay current spot price here for 1PLCO2 carbon credits
    // Verify transaction details at www.1PLANET.app
    //-------------------------------------------------------------------------------------------
    function offsetDirectWithETH(string calldata message) external payable OnePlanetOffset returns (bool success) {
        
        require(msg.value > 0, "You need to send at least some ETH");
        ethAmount = safeMul(msg.value, safeDiv(1e18, offsetSigDigits));
        uint tokens = safeDiv(ethAmount, ethPrice1PL);
        
        // tokens = safeDiv(tokens, offsetSigDigits);
        tokens = safeMul(tokens, offsetSigDigits); // only retire in kg
        balances[retireAddress] = safeAdd(balances[retireAddress], tokens);
        emit Transfer(address(0), retireAddress, tokens);
        emit CarbonOffset(message);
        _totalSupply = safeAdd(_totalSupply, tokens);
        getLatestPrice();
        return true;
    }
        
    function set1PLpriceInt(uint price) public onlyOwner {
        tokenPrice = price;
    }
	
	function updateOracleAddress(address payable newOracleAddress) public onlyOwner {
        oracleAddress = newOracleAddress;
        priceFeed = AggregatorV3Interface(oracleAddress);
	}

    function setRetireAddress(address newAddress) public onlyOwner {
        retireAddress = newAddress;
    }
    
    function updateGasCO2factor (uint256 CO2factor) external onlyOwner {
        gasCO2factor = CO2factor;
    }
    
    function updateCO2factor1 (uint256 CO2factor) external onlyOwner {
        CO2factor1 = CO2factor;
    }
    
    function updateCCO2factor2 (uint256 CO2factor) external onlyOwner {
        CO2factor2 = CO2factor;
    }
    
    function updateCCO2factor3 (uint256 CO2factor) external onlyOwner {
        CO2factor3 = CO2factor;
    }
    
    function updateCCO2factor4 (uint256 CO2factor) external onlyOwner {
        CO2factor4 = CO2factor;
    }
    
    function updateCCO2factor5 (uint256 CO2factor) external onlyOwner {
        CO2factor5 = CO2factor;
    }
    
    
    function setOracleUpdateInterval(uint interval) public onlyOwner {
        updateInterval = interval;
    }

    function genAndSendTokens(address to, uint tokens) external onlyOwner returns (bool success) {
        require(now >= startDate && now <= endDate);
        require(_maxSupply >= safeAdd(_totalSupply, tokens));
        balances[to] = safeAdd(balances[to], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        emit Transfer(address(0), to, tokens);
        
        return true;
    }

    //-----------------------------------------------------
    // Returns the latest Chainlink Oracle ETH USD price
    //-----------------------------------------------------
    function getLatestPrice() public {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        ethPrice = safeDiv(uint(price), 1000000);
        uint256 temp = safeMul(tokenPrice, 1e18);
        ethPrice1PL = safeDiv(temp, ethPrice);
    }

    function updateEthPriceManually(uint price) external onlyOwner {
        ethPrice = price;
    }
    
    function update1PLethPriceManually(uint price) external onlyOwner {
        ethPrice1PL = price;
    }
    
    
    //--------------------------------------------------------------------------------------
    // Added due to Matic <-> Ethereum PoS transfer requiring 1PLCO2 on Matic network to be
    // burned or minted. Eth supply can be increased if it is ever necessary.
    //--------------------------------------------------------------------------------------
    function setMaxVolume(uint maxVolume) external onlyOwner {
        _maxSupply = maxVolume;
    }
    
    //--------------------------------------------------------------------------------------
    // Oracle returns price in decimal cents to 2 decimal places. If this changes it can
    // be adjusted by changing this significant digit value.
    // Should be a power of 10.
    //--------------------------------------------------------------------------------------
    function setEthSigDigits(uint digits) external onlyOwner {
        SigDigits = digits;
    }
    
    function setOffsetSigDigits(uint digits) external onlyOwner {
        offsetSigDigits = digits;
    }

    function withdrawFromBalance() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    
    function removePermanently(address account, uint256 amount) external returns (bool success) {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        balances[account] = safeSub(balances[account],amount);
        _totalSupply = safeSub(_totalSupply, amount);
        emit Transfer(account, address(0), amount);
        
        return true;
    }
        /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
        function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
        

}