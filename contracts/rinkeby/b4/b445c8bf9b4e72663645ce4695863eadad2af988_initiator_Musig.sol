/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// File: contracts/Elliptical.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12 <0.7.0;

/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves.
 * This library does not check whether the inserted points belong to the curve
 * `isOnCurve` function should be used by the library user to check the aforementioned statement.
 * @author Witnet Foundation
 */
library Elliptical {

  // Pre-computed constant for 2 ** 255
  uint256 constant private U255_MAX_PLUS_1 = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  /// @dev Modular euclidean inverse of a number (mod p).
  /// @param _x The number
  /// @param _pp The modulus
  /// @return q such that x*q = 1 (mod _pp)
  function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
    require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
    uint256 q = 0;
    uint256 newT = 1;
    uint256 r = _pp;
    uint256 t;
    while (_x != 0) {
      t = r / _x;
      (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
      (r, _x) = (_x, r - t * _x);
    }

    return q;
  }

  /// @dev Modular exponentiation, b^e % _pp.
  /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
  /// @param _base base
  /// @param _exp exponent
  /// @param _pp modulus
  /// @return r such that r = b**e (mod _pp)
  function expMod(uint256 _base, uint256 _exp, uint256 _pp) internal pure returns (uint256) {
    require(_pp!=0, "Modulus is zero");

    if (_base == 0)
      return 0;
    if (_exp == 0)
      return 1;

    uint256 r = 1;
    uint256 bit = U255_MAX_PLUS_1;
    assembly {
      for { } gt(bit, 0) { }{
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, bit)))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), _pp)
        bit := div(bit, 16)
      }
    }

    return r;
  }

  /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
  /// @param _x coordinate x
  /// @param _y coordinate y
  /// @param _z coordinate z
  /// @param _pp the modulus
  /// @return (x', y') affine coordinates
  function toAffine(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _pp)
  public pure returns (uint256, uint256)
  {
    uint256 zInv = invMod(_z, _pp);
    uint256 zInv2 = mulmod(zInv, zInv, _pp);
    uint256 x2 = mulmod(_x, zInv2, _pp);
    uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

    return (x2, y2);
  }

  /// @dev Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
  /// @param _prefix parity byte (0x02 even, 0x03 odd)
  /// @param _x coordinate x
  /// @param _aa constant of curve
  /// @param _bb constant of curve
  /// @param _pp the modulus
  /// @return y coordinate y
  function deriveY(
    uint8 _prefix,
    uint256 _x,
    uint256 _aa,
    uint256 _bb,
    uint256 _pp)
  internal pure returns (uint256)
  {
    require(_prefix == 0x02 || _prefix == 0x03, "Invalid compressed EC point prefix");

    // x^3 + ax + b
    uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, _pp), _pp), addmod(mulmod(_x, _aa, _pp), _bb, _pp), _pp);
    y2 = expMod(y2, (_pp + 1) / 4, _pp);
    // uint256 cmp = yBit ^ y_ & 1;
    uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : _pp - y2;

    return y;
  }

  /// @dev Check whether point (x,y) is on curve defined by a, b, and _pp.
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _aa constant of curve
  /// @param _bb constant of curve
  /// @param _pp the modulus
  /// @return true if x,y in the curve, false else
  function isOnCurve(
    uint _x,
    uint _y,
    uint _aa,
    uint _bb,
    uint _pp)
  internal pure returns (bool)
  {
    if (0 == _x || _x >= _pp || 0 == _y || _y >= _pp) {
      return false;
    }
    // y^2
    uint lhs = mulmod(_y, _y, _pp);
    // x^3
    uint rhs = mulmod(mulmod(_x, _x, _pp), _x, _pp);
    if (_aa != 0) {
      // x^3 + a*x
      rhs = addmod(rhs, mulmod(_x, _aa, _pp), _pp);
    }
    if (_bb != 0) {
      // x^3 + a*x + b
      rhs = addmod(rhs, _bb, _pp);
    }

    return lhs == rhs;
  }

  /// @dev Calculate inverse (x, -y) of point (x, y).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _pp the modulus
  /// @return (x, -y)
  function ecInv(
    uint256 _x,
    uint256 _y,
    uint256 _pp)
  internal pure returns (uint256, uint256)
  {
    return (_x, (_pp - _y) % _pp);
  }

  /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = P1+P2 in affine coordinates
  function ecAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
    internal pure returns(uint256, uint256)
  {
    uint x = 0;
    uint y = 0;
    uint z = 0;

    // Double if x1==x2 else add
    if (_x1==_x2) {
      // y1 = -y2 mod p
      if (addmod(_y1, _y2, _pp) == 0) {
        return(0, 0);
      } else {
        // P1 = P2
        (x, y, z) = jacDouble(
          _x1,
          _y1,
          1,
          _aa,
          _pp);
      }
    } else {
      (x, y, z) = jacAdd(
        _x1,
        _y1,
        1,
        _x2,
        _y2,
        1,
        _pp);
    }
    // Get back to affine
    return toAffine(
      x,
      y,
      z,
      _pp);
  }

  /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = P1-P2 in affine coordinates
  function ecSub(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
  internal pure returns(uint256, uint256)
  {
    // invert square
    (uint256 x, uint256 y) = ecInv(_x2, _y2, _pp);
    // P1-square
    return ecAdd(
      _x1,
      _y1,
      x,
      y,
      _aa,
      _pp);
  }

  /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
  /// @param _k scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = d*P in affine coordinates
  function ecMul(
    uint256 _k,
    uint256 _x,
    uint256 _y,
    uint256 _aa,
    uint256 _pp)
  internal pure returns(uint256, uint256)
  {
    // Jacobian multiplication
    (uint256 x1, uint256 y1, uint256 z1) = jacMul(
      _k,
      _x,
      _y,
      1,
      _aa,
      _pp);
    // Get back to affine
    return toAffine(
      x1,
      y1,
      z1,
      _pp);
  }

  /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _z1 coordinate z of P1
  /// @param _x2 coordinate x of square
  /// @param _y2 coordinate y of square
  /// @param _z2 coordinate z of square
  /// @param _pp the modulus
  /// @return (qx, qy, qz) P1+square in Jacobian
  function jacAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _z1,
    uint256 _x2,
    uint256 _y2,
    uint256 _z2,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_x1==0 && _y1==0)
      return (_x2, _y2, _z2);
    if (_x2==0 && _y2==0)
      return (_x1, _y1, _z1);

    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    uint[4] memory zs; // z1^2, z1^3, z2^2, z2^3
    zs[0] = mulmod(_z1, _z1, _pp);
    zs[1] = mulmod(_z1, zs[0], _pp);
    zs[2] = mulmod(_z2, _z2, _pp);
    zs[3] = mulmod(_z2, zs[2], _pp);

    // u1, s1, u2, s2
    zs = [
      mulmod(_x1, zs[2], _pp),
      mulmod(_y1, zs[3], _pp),
      mulmod(_x2, zs[0], _pp),
      mulmod(_y2, zs[1], _pp)
    ];

    // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
    require(zs[0] != zs[2] || zs[1] != zs[3], "Use jacDouble function instead");

    uint[4] memory hr;
    //h
    hr[0] = addmod(zs[2], _pp - zs[0], _pp);
    //r
    hr[1] = addmod(zs[3], _pp - zs[1], _pp);
    //h^2
    hr[2] = mulmod(hr[0], hr[0], _pp);
    // h^3
    hr[3] = mulmod(hr[2], hr[0], _pp);
    // qx = -h^3  -2u1h^2+r^2
    uint256 qx = addmod(mulmod(hr[1], hr[1], _pp), _pp - hr[3], _pp);
    qx = addmod(qx, _pp - mulmod(2, mulmod(zs[0], hr[2], _pp), _pp), _pp);
    // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
    uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp), _pp);
    qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
    // qz = h*z1*z2
    uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
    return(qx, qy, qz);
  }

  /// @dev Doubles a points (x, y, z).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @param _aa the a scalar in the curve equation
  /// @param _pp the modulus
  /// @return (qx, qy, qz) 2P in Jacobian
  function jacDouble(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_z == 0)
      return (_x, _y, _z);

    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
    // x, y, z at this point represent the squares of _x, _y, _z
    uint256 x = mulmod(_x, _x, _pp); //x1^2
    uint256 y = mulmod(_y, _y, _pp); //y1^2
    uint256 z = mulmod(_z, _z, _pp); //z1^2

    // s
    uint s = mulmod(4, mulmod(_x, y, _pp), _pp);
    // m
    uint m = addmod(mulmod(3, x, _pp), mulmod(_aa, mulmod(z, z, _pp), _pp), _pp);

    // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
    // This allows to reduce the gas cost and stack footprint of the algorithm
    // qx
    x = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
    // qy = -8*y1^4 + M(S-T)
    y = addmod(mulmod(m, addmod(s, _pp - x, _pp), _pp), _pp - mulmod(8, mulmod(y, y, _pp), _pp), _pp);
    // qz = 2*y1*z1
    z = mulmod(2, mulmod(_y, _z, _pp), _pp);

    return (x, y, z);
  }

  /// @dev Multiply point (x, y, z) times d.
  /// @param _d scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @param _aa constant of curve
  /// @param _pp the modulus
  /// @return (qx, qy, qz) d*P1 in Jacobian
  function jacMul(
    uint256 _d,
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    // Early return in case that `_d == 0`
    if (_d == 0) {
      return (_x, _y, _z);
    }

    uint256 remaining = _d;
    uint256 qx = 0;
    uint256 qy = 0;
    uint256 qz = 1;

    // Double and add algorithm
    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        (qx, qy, qz) = jacAdd(
          qx,
          qy,
          qz,
          _x,
          _y,
          _z,
          _pp);
      }
      remaining = remaining / 2;
      (_x, _y, _z) = jacDouble(
        _x,
        _y,
        _z,
        _aa,
        _pp);
    }
    return (qx, qy, qz);
  }
}
// File: contracts/initiator_Musig.sol


pragma solidity ^0.6.12;


contract Requestor{
	 
    string Query='no message';
	address owner;
	uint _start;
    uint _end;
	address _ini;
	string Updated_Requestor;
	bool value=false;
	 struct  ver{ 
		string Message;
        uint256 sG_xcordinatee;
		uint256 sG_ycordinatee;
        uint256 rhs_xxx;
		uint256 rhs_yyy;
        bool signaturee;
		address _initiatorr;
        //uint256 e;
    }
	ver public details;
	
    constructor() public {
      owner = msg.sender;
     }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    modifier timeOver{
       require(now<=_end,"The time is Over");
       _;
   }

    
  
	function invest() external payable onlyOwner{

	}
	
	function send_incetives(address _init)public   payable onlyOwner {
		if(value==true){
        payable(_init).transfer(address(this).balance);
		}
		else {
			payable(msg.sender).transfer(address(this).balance);
		}
		payable(msg.sender).transfer(address(this).balance);
	}
   
	
/*    function check() public {
        if(value==true){}
        send_incetives(_initiator);
    } */
	

   
	function balance_deposit() external view returns(uint){
		return address(this).balance;
	}

   function start() private {
        _start = now;
    } 

    function end(uint totalTime) private{
        _end = totalTime + _start;
    }  
    
	function Check_reply(address payable _contract) public onlyOwner view returns (string memory){
		initiator_Musig _duplicatee = initiator_Musig(_contract);
		_duplicatee.status();
	}

    function getTimeLeft() public view returns(uint){
        return _end-now;
    }
    
    function Create_info(string memory _info) public onlyOwner{
		assert(address(this).balance>1);
		Updated_Requestor='yes';
		Query = _info;
		start();
		end(1000000);
	}
    
    
	function display_info() public view returns(string memory){
		return Query;
	}
    
	/*function clear() public onlyOwner {
		information='no message';
	    sG_xcordinate=0;
	    sG_ycordinate=0;
	    rhs_xx=0;
	    rhs_yy=0;
	}*/
  

    function verify_details(string memory _msg,bool _sig,address _initi) public view onlyOwner returns(string memory Msg_from_initiator,bool _Signature,address Initiator_PublicKey){
		Msg_from_initiator=_msg;
		_Signature = _sig;
		Initiator_PublicKey = _initi;
	} 


	
    function verifyy(address payable  _contract)  public   onlyOwner returns(bool,string memory) /*returns(uint256 sG_xcordinate,uint256 sG_ycordinate,uint256 rhs_xx,uint256 rhs_yy,bool signature,address _initiator)*/{
		initiator_Musig _duplicate = initiator_Musig(_contract);
	//	(sG_xcordinate,sG_ycordinate, rhs_xx, rhs_yy, signature,_initiator) =_duplicate.verify();
		(details.Message,details.sG_xcordinatee,details.sG_ycordinatee, details.rhs_xxx, details.rhs_yyy,details.signaturee,details._initiatorr) =_duplicate.verify();
		verify_details(details.Message,details.signaturee,details._initiatorr);
		//value=details.signaturee;
		//Updated_Requestor='No';
		
		//send_incetives(_initiator);
		//_ini = _initiator;
		value=details.signaturee;
		send_incetives(details._initiatorr);
		
	   

    }

}




contract initiator_Musig {

    struct  Details{ 
        uint256 Publickey_x;
		uint256 Publickey_y;
        uint256 R_x;
		uint256 R_y;
        uint256 s;
        //uint256 e;
    }
	struct  Basic_Details{ 
        string message;
		uint256 Total_number;
        uint256 required;
	
    }
	struct Combined{
		uint256  publickey_combined_x;
      	uint256  publickey_combined_y;
	    uint256  R_combined_x;
	    uint256  R_combined_y;
	    uint256  s_combined;
	}

    address owner;
    constructor() public {
      owner = msg.sender;
     }



    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
    
    
	modifier timeOver{
       require(now<=_end,"The time is Over");
       _;
   }



    mapping(uint  => Details) public user;
	mapping(uint256 => address) public witness_address;
    uint256  count=0;
    uint256 constant  g_x = 0xdb4ff10ec057e9ae26b07d0280b7f4341da5d1b1eae06c7d;
    uint256 constant  g_y = 0x9b2f2f6d9c5628a7844163d015be86344082aa88d95e2f9d;
    uint256 constant  n = 0xfffffffffffffffffffffffffffffffffffffffeffffee37;
    uint256 constant  a = 0x000000000000000000000000000000000000000000000000;
    uint256 constant  b = 0x000000000000000000000000000000000000000000000003;
	uint256 public e;
	uint256 public totalnumberofpeoplesigned=0;
    Basic_Details public msg_total_required;
	Combined public Combined_keys;
	uint256 ccount=1;
	uint _start;
    uint _end;
	string public status='No';
	uint256 public time_start;
	uint256 public time_end;
  
   function set_status(string memory _stat) public returns(string memory){
	   status= _stat;
   }
  
  function get_msg(address _contract) public view returns(string memory){
		Requestor _duplicatee = Requestor(_contract);
		 return(_duplicatee.display_info());
	  //  if(signature){
		//	    payable().transfer(1 ether);
		//}
}
   
   function start() private {
        _start = now;
    } 

    function end(uint totalTime) private{
        _end = totalTime + _start;
    }  
  

    function getTimeLeft() public view returns(uint){
        return _end-now;
    }

     function invest() external payable{

	}

	  function sendEther() public  payable onlyOwner {
        // This function is no longer recommended for sending Ether.
		  for (uint256 k = 1; k < count; k++){
          payable(witness_address[k]).transfer(1 ether);
		  }
		  msg.sender.transfer(address(this).balance);

        //_to.transfer(1 ether);
    }
    fallback() external payable {}
	receive() external payable {
        // custom function code
    }

    function  set_message_TotalNumber_R(string memory _msg , uint256 _total_people ,uint256 _required,uint256 EPHERIMAL_I,uint256 priv_I) public onlyOwner{
		
		msg_total_required.message=_msg;
		msg_total_required.Total_number=_total_people;
		msg_total_required.required=_required;
		start();
		end(1000000);
		//_start = now;
		//_end = 500 + _start;
		//invest();
		sign_(EPHERIMAL_I,priv_I);
	}

    function sign_( uint256 Epherimalkey,uint256 privKey)
	    timeOver  public 
	{
        time_start = block.timestamp;
		assert(address(this).balance>msg_total_required.required);
		if(count<msg_total_required.required){
		totalnumberofpeoplesigned=totalnumberofpeoplesigned+1;
		
		Details storage user1 = user[count];
		witness_address[count] = msg.sender;
		count = count+1;
		
		if(msg.sender == witness_address[count-1]){
        (user1.Publickey_x,user1.Publickey_y)= Elliptical.ecMul(privKey,g_x,g_y,a,n); // publickey =privatekey * Generator 
		(user1.R_x,user1.R_y)= Elliptical.ecMul(Epherimalkey,g_x,g_y,a,n);            //  R(nonce) = Epherimalkey * Generator
		e = uint(keccak256(abi.encodePacked(msg_total_required.message)))%n; // e=H(publickey || message)
		user1.s = Epherimalkey+e*privKey;   // (epherimal key +e *private key)
		}

		if(count==msg_total_required.required){
			sign_for();
			set_status('Work Done');
			//sendEther();
		}
		time_end=block.timestamp-time_end;
	}
	}
   
	
		function sign_for() internal
        {   
            
			(Combined_keys.publickey_combined_x,Combined_keys.publickey_combined_y)= Elliptical.ecAdd(user[0].Publickey_x,user[0].Publickey_y,user[1].Publickey_x,user[1].Publickey_y,a,n);
            (Combined_keys.R_combined_x,Combined_keys.R_combined_y)= Elliptical.ecAdd(user[0].R_x,user[0].R_y,user[1].R_x,user[1].R_y,a,n);
			Combined_keys.s_combined=(user[0].s+user[1].s);
			for(uint256 i=2;i<totalnumberofpeoplesigned;i++){
				//(publickey_user1_x,publickey_user1_y,R_user1_x,R_user1_y,s_user1,e_combines) = sign_(privatekey_user1,Epherimalkey_user1);
                //(publickey_user2_x,publickey_user2_y,R_user2_x,R_user2_y,s_user2,e_combines) = sign_(privatekey_user2,Epherimalkey_user2);

                (Combined_keys.publickey_combined_x,Combined_keys.publickey_combined_y)= Elliptical.ecAdd(Combined_keys.publickey_combined_x,Combined_keys.publickey_combined_y,user[i].Publickey_x,user[i].Publickey_y,a,n);
                (Combined_keys.R_combined_x,Combined_keys.R_combined_y)= Elliptical.ecAdd(Combined_keys.R_combined_x,Combined_keys.R_combined_y,user[i].R_x,user[i].R_y,a,n);

                //e_combines=uint(keccak256(abi.encodePacked(message)))%n; 
                Combined_keys.s_combined=(Combined_keys.s_combined+user[i].s);
			}
            
            //sendEther();
    }

    function verify_lhs(uint256 s)  internal pure returns (uint256 sG_x,uint256 sG_y)
	{
         (sG_x,sG_y) =  Elliptical.ecMul(s,g_x,g_y,a,n);  // verification left side  s*Generator
		
	}
    
	function verify_rhs(uint256 r_x,uint r_y,uint256 pub_x,uint256 pub_y,uint _e) internal pure returns(uint256 rhs_x,uint256 rhs_y){
		
	     (uint256 z1,uint256 z2)=Elliptical.ecMul(_e,pub_x,pub_y,a,n);
	     (rhs_x,rhs_y)=Elliptical.ecAdd(r_x,r_y,z1,z2,a,n);              //verification righ side  R + e*Public key 
	 
	}

/*	function verify(uint256 publickey_x,uint256 publickey_y,uint256 R_x,uint256 R_y,uint _s,uint256 out_ee) public  pure returns(uint256 sG_xcordinate,uint256 sG_ycordinate,
	uint256 rhs_xx,uint256 rhs_yy,bool signature){

		// s*G == R + e*Public key
		(sG_xcordinate, sG_ycordinate)   = verify_lhs(_s);
		(rhs_xx, rhs_yy) = verify_rhs(R_x,R_y,publickey_x,publickey_y,out_ee);

		signature = (sG_xcordinate == rhs_xx);
		//bool right = (sG_ycordinate == rhs_yy);
		//if(sG_xcordinate == rhs_xx){
          // payable(witness_address[0]).transfer(1 ether);
		//}
	}
*/

	function verify()  public view returns(string memory Message,uint256 sG_xcordinate,uint256 sG_ycordinate,
	uint256 rhs_xx,uint256 rhs_yy,bool signature,address _initiator){

		// s*G == R + e*Public key
		(sG_xcordinate, sG_ycordinate)   = verify_lhs(Combined_keys.s_combined);
		(rhs_xx, rhs_yy) = verify_rhs(Combined_keys.R_combined_x,Combined_keys.R_combined_y,Combined_keys.publickey_combined_x,Combined_keys.publickey_combined_y,e);
        _initiator=witness_address[0];
		signature = (sG_xcordinate == rhs_xx);
		Message = msg_total_required.message;
		/*if(signature){
		for(uint k=0;k<msg_total_required.required;k++){
			 payable(witness_address[k]).transfer(1 ether);
		  }
		  msg.sender.transfer(address(this).balance);
		}*/
		
		
		//bool right = (sG_ycordinate == rhs_yy);
		//if(sG_xcordinate == rhs_xx){
          // payable(witness_address[0]).transfer(1 ether);
		//}
	}
	

	function clear() public onlyOwner{
		totalnumberofpeoplesigned=0;
		count=0;
		msg_total_required.message='EMPTY';
		msg_total_required.Total_number=0;
		msg_total_required.required=0;
		delete Combined_keys;
		e=0;
		//for(int z=0;user[0].user1.Detailss)
	} 
   //0xF67bA4af33392a897A8f272EBC534D07875FE2d7
   //0x319C0eb84244d9EFe0C0C6EBA7583661B8aA813A
  //0x0FDfFb80945fDd5ac8bf263171521D5F2379388F
  //0xd357c548dEE15Faf93240d1996c5F41aE1a6C884

	function balance_deposit() public  view returns(uint){
		return address(this).balance;
	}
    


}