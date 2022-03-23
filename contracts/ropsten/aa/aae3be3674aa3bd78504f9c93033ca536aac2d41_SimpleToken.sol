/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/**
* Interface 는 사용할 함수의 형태를 선언합니다.
* 실제 함수의 내용은 Contract 에서 사용합니다.
* function 은 이더리움에서 제공하는 함수
* event 는 이더리움에서 제공하는 로그
*/
interface ERC20Interface{
    // 해당 스마트 컨트랙트 기반 ERC-20 토큰의 총 발행량 확인
    function totalSupply () external view returns (uint256);
    
    // owner 가 가지고 있는 토큰의 보유량 확인
    function balanceOf (address account) external view returns (uint256);
    
    // 토큰 전송
    function transfer (address recipient, uint256 amount) external returns (bool);
    
    // spender 에게 value 만큼의 토큰을 인출할 권리를 부여, 이 함수를 이용할 때는 반드시 Approval 이벤트 함수를 호출해야 한다. approve:승인하다
    function approve (address spender, uint256 amount) external returns (bool);

    // owner 가 spender 에게 양도 설정한 토큰의 양을 확인. allowance : 양도한 토큰양, spender : 토큰 양도받은 사람
    function allowance(address owner, address spender) external view returns (uint256);

    // spender 가 거래가능 하도록 양도 받은 토큰을 전송. recipient : 받는사람
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);

    /* Transfer 이벤트는 토큰이 이동할 때마다 로그를 남깁니다 */
    /* Approval 이벤트는 approve 함수가 실행될 때 로그를 남깁니다. */
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 oldAmount, uint256 amount);
}


contract SimpleToken is ERC20Interface{
    mapping (address => uint256) private _balances;     // (토큰 소유자:소유한 토큰액) 기록
    mapping (address => mapping (address => uint256)) public _allowances; // (토큰 양도받은자 : 토큰 주인 : 양도받은 토큰액 ) 기록

    uint256 public _totalSupply;    // 토큰 총 발행양
    string public _name;            // 토큰 이름
    string public _symbol;          // 토큰 단위
    uint8 public _decimals;

    constructor (string memory getName, string memory getSymbol){
        _name = getName;    // 토큰 이름
        _symbol = getSymbol; // 토큰 단위
        _decimals = 18;
        _totalSupply = 100000000e18; // 총 토큰의 양
        _balances[msg.sender] = _totalSupply; // 컨트랙트를 실행한 사람은 최초 발행자가 되어 우선적으로 총 토큰의 양을 가지게 됩니다.

    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint8){
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns(uint256){
        return _balances[account];
    }

    /* 이거는 ERC20Interface 에서 상속한것이다.
    /* 토큰 직거래 함수, 받는사람 주소와 토큰양을 지정하면, 주소유무와 잔액검증 후에, 받는사람에게 amount 만큼 토큰을 더해줍니다.*/    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool){
        _transfer(msg.sender, recipient, amount); // 검증후 보내는것
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /* 토큰 직거래 함수 내부기능, 주소및 토큰양 검증후, sender 가 recipient 에게 토큰을 직접 건넵니다.*/
    function _transfer(address sender, address recipient, uint256 amount) internal virtual{
        // require 를 통해 세가지 조건 검사
        require(sender != address(0), "ERC20: transfer from the zero address"); // 보내는 사람의 주소가 없다? address 의 null 검사?
        require(recipient != address(0), "ERC20 : transfer to the zero address"); // 받는사람의 주소가 없다

        uint256 senderBalance = _balances[sender]; // 요청한 사람의 잔액
        
        require(senderBalance >= amount, "ERC20 : transfer amount exeed balance"); // 보낸사람의 토큰 잔액이 보내려는값보다 커야한다, 아니면 에러.

        // 송금 처리
        _balances[sender] = senderBalance-amount;
        _balances[recipient] += amount;
    }

    // 토큰 양도금 설정 및 승인. spender 가 당신의 계정으로부터 amount 한도 하에서 여러번 출금하는것을 허용하는 함수
    /* 판매자가 여러 사람한테 토큰 양도금 을 설정하여, 자신이 보유한 토큰 양보다, 다수의 양도인이 양도받은 총 토큰의 양이 커지는 문제가 있다. */
    /* 즉.. A 는 100 토큰을 보유하였으며, B 에게 60 토큰 양도, C 에게 60 토큰 양도 하였으며 , D 가 보유한 토큰은 0 일때.. 
        이와같이 표현할수 있다고 한다면 [ A:100, B:(A:60), C:(A:60), D:0 ] 
        이 경우, A는 토큰 100개 를 소유하고 있지만 총 120개를 양도하였음에도, 에러는 발생하지 않으며,
        
        B 가, A 로부터 양도받은 60 토큰을 D 에게 판다면.. A:40, B:(A:0), C:(A:60), D:60 으로 표현할 수 있다.
        이때 C 가 A로부터 양도받은 토큰 A:60 을 D 에게 판다면.. 
        C 는 A:60 을 양도받았음에도 불구하고, A는 실제 A:40 만큼 들고 있으니. 이 경우 다행이 에러가 난다.
        
        하지만 다른 사람한테 양도한 토큰의 양 을 다른 양도자는 모르니 개선이 필요하다.
        A 가 양도한 총 토큰의 양을 따로 저장한다면, 어떨까?
     */
    function approve (address spender, uint amount) external virtual override returns (bool){
        uint256 currentAllowance = _allowances[msg.sender][spender]; // _allowances[주인][양도받은자] = 원래주인으로부터 양도받은 토큰양
        //require(currentAllowance >= amount, "ERC20 : transfer amount exceeds allowance"); // 잘못된 코드
        require(_balances[msg.sender] >= amount,"ERC20 : transfer amount exeed onwer balance");
        _approve(msg.sender, spender, currentAllowance, amount);
        return true;
    }

    // 토큰 양도 설정, Spender 에게 맡긴 양도한 토큰을 실제로 기록하는 함수.
    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual{
        require(owner != address(0),"ERC20 : approve from the zero address."); //적합하지 않은 주소가 승인하려고 합니다
        require(spender != address(0), "ERC20 : approve to the zero address."); //적합하지 않은 주소에게 승인하려고 합니다
        require(currentAmount == _allowances[owner][spender], "ERC20 : invalid current Amount.");//유효하지 않은 양입니다

        // 토큰 양도
        _allowances[owner][spender] = amount;
        emit Approval(owner,spender,currentAmount, amount);
    }
    
    // owner가 spender에게 토큰을 등록한 양을 반환
    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
    }

    // 양도를 통한 토큰 거래
    function transferFrom (address sender, address recipient, uint256 amount) external virtual override returns(bool){
        uint256 currentAllowance = _allowances[sender][msg.sender]; // spender 중개자가 출금하나 보다.
        require(currentAllowance >= amount, "ERC20 : transfer amount exceeds allowance"); // 양도자는 양도받은 금액 이하의 양을 판매해야 합니다.

        _transfer(sender, recipient, amount); // 송금처리
        emit Transfer(msg.sender, sender, recipient, amount);
        _approve(sender,msg.sender, currentAllowance, currentAllowance-amount); // 양도금 정산
        
        return true;
    }


}