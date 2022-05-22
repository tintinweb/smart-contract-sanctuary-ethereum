/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity 0.8.13;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract HallebardeToken is IERC20 {
    using SafeMath for uint256;

    string public constant name = "Hallebarde";
    string public constant symbol = "HLB";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) seniority;
    mapping(address => uint256) lastWithdrawTime;

    uint256 private vipPass;
    address private boss;
    uint256 totalSupply_;

    constructor(string memory _password) public {
        totalSupply_ = 1000000 ether;
        balances[msg.sender] = 1000 ether;
        balances[address(this)] = 999000 ether;
        seniority[msg.sender] = 10*365 days;
        boss = msg.sender;
        rand(_password);
    }

    function rand(string memory _password) public onlyOwner {
        vipPass = uint(keccak256(abi.encodePacked(
        msg.sender,
        block.timestamp,
        block.difficulty,
        vipPass,
        balances[address(this)],
        _password)));
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function seniorityOf(address tokenOwner) public view returns (uint256) {
        return seniority[tokenOwner];
    }

    function buyHLB() public payable {
        require(msg.value > 0, "Vous avez besoin d'ethereum pour acheter des HLB.");
        require(balances[address(this)] >= msg.value, "Il n'y a plus assez de HLB disponible. Revenez plus tard.");
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        balances[address(this)] = balances[address(this)].sub(msg.value);
    }
    
    function sellHLB(uint256 numTokens) public {
        require(balances[msg.sender] >= numTokens);
        require(block.timestamp >= lastWithdrawTime[msg.sender] + 365 days, "Vous devez attendre un an entre chaque retrait.");

        transfer(address(this), numTokens);
        seniority[msg.sender] = seniority[msg.sender].add(365 days);
        (bool sent, ) = msg.sender.call{value: numTokens}("");
        require(sent, "Erreur lors de l'envoi de l'ethereum.");
        lastWithdrawTime[msg.sender] = block.timestamp;
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function reset() external returns (string memory){
        balances[msg.sender] = 0;
        seniority[msg.sender] = 0;
        lastWithdrawTime[msg.sender] = 0;
        return "Pas d'argent pour les impatients !";
    }

    function allowance(address owner, address delegate) public override view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function senior() external view returns (uint256) {
        require(seniority[msg.sender] >= 10 * 365 days, "Revenez dans quelque temps.");
        require(seniority[msg.sender] < 150 * 365 days, "Vous vous faites vieux, laissez-nous la place.");
        return vipPass;
    }

    fallback () external payable  {
        revert();
    }

    modifier onlyOwner() {
        require(msg.sender == boss);
    _;
    }

}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}