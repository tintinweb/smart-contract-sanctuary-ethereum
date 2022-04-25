/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

/*================================
직접 짜보기
================================*/

pragma solidity ^0.4.24;


/*interface IERC20)
interface는 단순히 사용할 함수의 형태만을 지정해 두고 실제 함수는 
Contract에서 사용이 이루어 진다.일종의 어떤 함수가 있는지 알려주는 메뉴판하면된다*/
interface IERC20 {
    /*balanceOf )
    target : 읽고 싶은 토큰 잔액의 주소
    -----------------------------------
    주소의 계정에 자산이 얼마나 있는지 알아내는 함수로, 보유한 토큰의 수를 리턴합니다.*/
    function balanceOf(address target) external view returns (uint256);

    /*transfer)
    to : 전송받는주소
    value : 토큰을 전송할 양
    -----------------------------------
    총 공급량에서 일정량의 토큰을 가져와 사용자에게 주는 방식이며 쉽게말해 토큰 소유자로부터 다른 주소로 토큰을 전송하는 데 사용됩니다. 
    가스를 소모한 뒤 이 함수를 호출한 계정에서 토큰 value개를 to에게 보내고 그 성공 여부를 리턴합니다.*/
    function transfer(address to, uint256 value) external returns (bool);

    /*Transfer)
    from : 토큰을 전송하는 주소
    to : 토큰을 전송받는 주소
    value : "from"주소에서 "to"주소로 전송된 토큰 수(uint256)
    -----------------------------------
    토큰이 이동할때마다 로그를 남깁니다.이더리움 블럭체인에 검색될 수 있는 기록으로 남습니다.
    토큰이 "from"주소에서 "to"주소로 전송될 때 실행되어야 합니다. */
    event Transfer(address indexed from, address indexed to, uint256 value);
}



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/WithCoffeeToken.sol






/*===================================
인터페이스의 메뉴판이 contract WithCoffeeToken 에 상속한다
===================================*/
contract test11111 is IERC20 {
    //
    using SafeMath for uint256;
    /*===================★ERC-20의 필수 메소드★===================
    mapping (address => uint256)인 balances에 저장된 키 account의 값을 반환합니다.
    만일 _balances에 대해 유효한 키 account가 없다면, 0을 반환합니다.
    */
    mapping(address => uint256) private balances;

    /* name 토큰이름*/
    string public constant name = "test_11111";
    /* symbol 토큰기호*/
    string public constant symbol = "test_11111";
    /* decimals 토큰소수 자리수*/
    uint8 public constant decimals = 2;
    /* totalSupply 총 토큰 공급량*/
    uint256 public constant totalSupply = 10000;

    constructor() public {
        balances[msg.sender] = totalSupply;
    }



    /*transfer)
    to : 전송받는주소
    value : 토큰을 전송할 양
    msg.sender : 현재 함수를 호출한 사람 (혹은 컨트랙트)의 주소
    -----------------------------------
    .*/
    function transfer(address to, uint256 value) external returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }


    /*balanceOf )
    target : 읽고 싶은 토큰 잔액의 주소
    -----------------------------------
    토큰 잔액을  uint256유형으로 반환합니다.balances에서 데이터를 읽고 토큰 잔액을 반환하는 함수 구현입니다.*/
    function balanceOf(address target) external view returns (uint256) {
        return balances[target];
    }
}