/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

pragma solidity ^0.4.26;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    string public name ;
    string public symbol;
    uint8 public constant decimals = 18;  
    uint256 public totalSupply;

    address public deployer;
    mapping(address => bool) nofees;
    address public dexPool;
    address public fund;

    address public blackHole;

    uint256 public feeBuyBurn = 10; // 10%
    uint256 public feeBuyPool = 10; // 10%
    uint256 public feeBuyFund = 10; // 10%
    uint256 public feeSellBurn = 10; // 10%
    uint256 public feeSellPool = 10; // 10%
    uint256 public feeSellFund = 10; // 10%
	
	uint256 private constant INITIAL_SUPPLY = 210700000 * (10 ** uint256(decimals));

    mapping (address => uint256) public balanceOf;  // 
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
	
	event Approval(address indexed owner, address indexed spender, uint256 value);

	modifier onlyDeployer() {
        require(msg.sender == deployer, "Only Deployer");
        _;
    }

    function setDeployer(address _dep) public onlyDeployer {
    	require(_dep != address(0), "deployer can't be zero");
    	deployer = _dep;
    }

    function setNofees(address _from, bool _flag) public onlyDeployer {
    	require(_from != address(0), "from can't be zero");
    	nofees[_from] = _flag;
    }

    function setDexPool(address _pool) public onlyDeployer {
    	require(_pool != address(0), "pool can't be zero");
    	dexPool = _pool;
    }

    function setFund(address _fund) public onlyDeployer {
    	require(_fund != address(0), "fund can't be zero");
    	fund = _fund;
    }

    function setBlackHole(address _b) public onlyDeployer {
    	require(_b != address(0), "blackHole can't be zero");
    	blackHole = _b;
    }

    function setFeeBuyBurn(uint256 _fee) public onlyDeployer {
    	require(_fee > 0, "fee can't be zero");
    	feeBuyBurn = _fee;
    }

    function setFeeBuyPool(uint256 _fee) public onlyDeployer {
    	require(_fee > 0, "fee can't be zero");
    	feeBuyPool = _fee;
    }

    function setFeeBuyFund(uint256 _fee) public onlyDeployer {
    	require(_fee > 0, "fee can't be zero");
    	feeBuyFund = _fee;
    }

    function setFeeSellBurn(uint256 _fee) public onlyDeployer {
    	require(_fee > 0, "fee can't be zero");
    	feeSellBurn = _fee;
    }

    function setFeeSellPool(uint256 _fee) public onlyDeployer {
    	require(_fee > 0, "fee can't be zero");
    	feeSellPool = _fee;
    }

    function setFeeSellFund(uint256 _fee) public onlyDeployer {
    	require(_fee > 0, "fee can't be zero");
    	feeSellFund = _fee;
    }

	constructor(string tokenName, string tokenSymbol) public {
		totalSupply = INITIAL_SUPPLY;
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;

        deployer = msg.sender;
    }


    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        //uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;

        if(dexPool != address(0) && !nofees[_from] && !nofees[_to]) {
        	if(_from == dexPool) {
        		balanceOf[_to] += (_value * (1000 - feeBuyBurn - feeBuyPool - feeBuyFund) / 1000);
        		balanceOf[blackHole] += (_value * feeBuyBurn / 1000);
        		balanceOf[dexPool] += (_value * feeBuyPool / 1000);
        		balanceOf[fund] += (_value * feeBuyFund / 1000);

        		emit Transfer(_from, _to, (_value * (1000 - feeBuyBurn - feeBuyPool - feeBuyFund) / 1000));
        		emit Transfer(_from, blackHole, (_value * feeBuyBurn / 1000));
        		emit Transfer(_from, dexPool, (_value * feeBuyPool / 1000));
        		emit Transfer(_from, fund, (_value * feeBuyFund / 1000));

    		} else if(_to == dexPool) {
    			balanceOf[_to] += (_value * (1000 - feeSellBurn - feeSellPool - feeSellFund) / 1000);
        		balanceOf[blackHole] += (_value * feeSellBurn / 1000);
        		balanceOf[dexPool] += (_value * feeSellPool / 1000);
        		balanceOf[fund] += (_value * feeSellFund / 1000);

        		emit Transfer(_from, _to, (_value * (1000 - feeSellBurn - feeSellPool - feeSellFund) / 1000));
        		emit Transfer(_from, blackHole, (_value * feeSellBurn / 1000));
        		emit Transfer(_from, dexPool, (_value * feeSellPool / 1000));
        		emit Transfer(_from, fund, (_value * feeSellFund / 1000));
    		} else {
		        balanceOf[_to] += _value;
		        emit Transfer(_from, _to, _value);
    		}
        } else {
	        balanceOf[_to] += _value;
	        emit Transfer(_from, _to, _value);
	    }
        //assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
		return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
		return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}