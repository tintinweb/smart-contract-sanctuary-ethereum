/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

/*================================
직접 짜보기1
================================*/

pragma solidity ^0.4.24;


/*interface IERC20) 
interface는 단순히 사용할 함수의 형태만을 지정해 두고 실제 함수는 Contract에서 사용이 이루어 진다.일종의 어떤 함수가 있는지 알려주는 메뉴판하면된다*/
interface IERC20 {
    /*balanceOf ) 주소의 계정에 자산이 얼마나 있는지 알아내는 함수로, 보유한 토큰의 수를 리턴한다*/
    function balanceOf(address target) external view returns (uint256); //target : 읽고 싶은 토큰 잔액의 주소 
    /*transfer) 토큰 소유자로부터 다른 주소로 토큰을 전송하는 데 사용된다.가스를 소모한 뒤 이 함수를 호출한 계정에서 토큰 (value)개를 (to)에게 보내고 그 성공 여부를 리턴한다*/
    function transfer(address to, uint256 value) external returns (bool); // to : 전송받는주소 , value : 토큰을 전송할 양
    /*Transfer) 토큰이 이동할때마다 이더리움 블록체인에 검색될 수 있는 기록을 남긴다.즉 로그를 남긴다*/
    event Transfer(address indexed from, address indexed to, uint256 value); // from : 토큰을 전송하는 주소 , to : 토큰을 전송받는 주소 , value : "from"주소에서 "to"주소로 전송된 토큰 수(uint256)
}


/*library SafeMath) 
일반적으로 스마트컨트랙트에서 숫자 연산을 할 때 공통적으로 발생하는 문제는 오버플로우, 언더플로우의 위험인데 예방합니다*/
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


/*인터페이스의 메뉴판인 IERC20을 test 에 상속한다*/
contract test is IERC20 {
    // using SafeMath) 자료형 uint256에 대해서 SafeMath라이브러리를 사용 한다는 의미이다.
    using SafeMath for uint256; 
    /* mapping ) balanceOf는 아래에 명시된 mapping (address => uint256)인 balances에 저장된 키 target의 값을 반환합니다.*/
    mapping(address => uint256) private balances;
    /* name 토큰이름*/
    string public constant name = "test11";
    /* symbol 토큰기호*/
    string public constant symbol = "TT11";
    /* decimals 토큰소수 자리수*/
    uint8 public constant decimals = 2;
    /* totalSupply 총 토큰 공급량*/
    uint256 public constant totalSupply = 100000;

    uint256 public constant unitsOneEthCanBuy = 10;
     
    /* 배포될때 한번만 실행되는 함수*/
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