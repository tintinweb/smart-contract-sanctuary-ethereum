/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

/**
                                                                                             
                                           ..:^~!!!!!~^.                                            
                                        :~7?JJ????JJJJJ?~.                                          
                                     .~?Y555555??JJJJJJYY~.                                         
                                   :!JYYYYY555PY?JJJYYYYYJ.                                         
                                 :!?JYYYYYYY55PYJYYYYYYY5J.                                         
                               .~?JJJJJYJ?7~~!JJYYYYY55557.                                         
                             .^7???????!:.   .~YYY555555P~                                          
                            :~77777?7~^:::.  .J555555PPPP7:::::^^^^^^::..                           
                          .:~!!!!77!^^^^^^^..75Y?!~~~7JPPP555PPPPPPPPP55YJ7^.                       
                         .^~~~~~!!~^^^^^^^:.^J?7!!~~^^^?GPPPPPPPPPPPPGG55555Y!.                     
                        .^^^^^~~~^^^^^^~~~::?J?77!!!!~^7GPPPPPPPPPPPPGGP55555P?.                    
                       .:^^^^^^~::~~~~~~~~:^YJJ7777!!!75GPPPPPPPPPGGGGG55555PPP~                    
                      .:^^^^^^^::^~~~~~~~~^:7YYJJ????YPGGGGGGGGPPGGGGGP55555PPP!.                   
                      .:^^::^^:.:!!!!!!!!!!^:^!77!!7??7!!~~~!?5GGGGGGP5PP5PPPP5^                    
                       ...:^^: .~!!7777!!!!!!~~~~~~~~~~~~^.   :YGGGGP5PPPPPPPP7.                    
                         .^^^:..~!7777777!!!7777777777777!:   .JBGPPPPPPPPPPP?.                     
                         .:::. .!7?????????????77777777!~:   :?GPPPPPPPPPPPP?.                      
                               .!7??????????????77!~^:..  .^75PPPPPPPPPPPP5!.                       
                               .~??????JJJJ??77~^.....:^!?YPPPPPPPPPPPPPP?:                         
                                ^?JJJJJJJJ??JJ7!!!7?Y5PPPPPPPPPPPPPPPPPJ^.                          
                                .~JJJJJJJJ?JGGGGGGGGGPPPPPPPPPPPPPPP5?^.                            
                                 .!YYYYYYJJPBGGGGGGGGGGGGGGGGPPPPPY7:.                              
                                  .~JYYYYJJPBGGGGGGGGGGGGGGGGGPY?^.                                 
                                    .~?Y55YYGBGGGGGGGGGGGGP5J!^.                                    
                                      .:~7?JJ5PGGGGPP5YJ7!^.                                        
                                           ..:::^^:::.                                              
                                                                                                    
                               ^?JJJJJYY?..^?JJ!.   :?J??^    .!JYY7.                               
                               ~55PPPGGG5:.755P5:   .!55P5~. .?GGG5^                                
                                .^YPPG?:. .755PY:    .^YPPP7^JGGGJ.                                 
                                 .YPPG?.  .755PY:      :JPPPPPGP7.                                  
                                 .YPPG?.  .755PY:       .7PPPP5~.                                   
                                .:YPPG?.  .755PY^.....   .YPPG7.                                    
                               ~Y5PPPGPP5:.755PP5PPPPP^  .YPPG7.                                    
                               ^JJJJYYY5J:.^JJJJYYYY5Y:  .7JYY~                                     
                                                                                                    
                                                                                                    
                                                                                                                                                                 
$ILY is a token based on the Ethereum network. Our goals is to Donate to Mental Health Organizations, 
Spread Positivity, and allow holders to vote using Web3!
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}



contract ILY is ERC20 {
    constructor(uint supply) ERC20("ILY TOKEN", "ILY") {
        _mint(msg.sender, supply);
    }
}