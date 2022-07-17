/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Address {
    function isContract(address account) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return true;
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165{

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenid);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenid);
    
    event ApprovedForall(address indexed owner , address indexed operator, bool approved);

    function balanceof(address owner )external view returns(uint256 balance);

function ownerof(uint256 tokenid)external view returns (address owner);


function safetransferfrom(
    address from,

    address to,

    uint256 tokenid,

    bytes calldata data
) external;

function safetransferfrom(
    address from,

    address to ,

    uint256 tokenid

)external;

function transferfrom(
    address from,

    address to,
    
    uint256 tokenid
)external ;
 
 function approve(address to, uint256 tokenid)external;

 function setapproveforAll(address operator, bool _approved)external;

 function getapproval(uint256 tokenid)external view returns(address operator );

 function isapproveForAll(address owner , address operator)external view returns(bool);

}

interface IERC721Receiver{

    //it is used to confirm that the token is transfer

        function onERC721Received(
        address operator,

        address from,

        uint256 tokenId,
        
        bytes calldata data
    ) external returns (bytes4);

}


interface IERC721Metadata is IERC721 {

    function name()external view returns(string memory);


    function symbol()external view returns (string memory);

    function tokenURI(uint256 tokenid)external view returns(string memory);

}



contract ERC721 is IERC721 , IERC721Metadata{

  
  using Address for address;
    

    string public _name;

    string public _symbol;


    mapping (uint256=>address)public _owners;

    mapping(uint256=>address)public _tokenApprovals;

    mapping (address => uint256)public _balances;

    mapping(address=>mapping(address=>bool))public _operatorApproval;

    constructor(string memory name_, string memory symbol_){
        _name=name_;

        _symbol=symbol_;
        
    }

    //function that is written through the IRC165 "supportsinterface"

  function supportsInterface(bytes4 interfaceId) public view virtual  returns(bool){

        interfaceId == type (IERC721).interfaceId ||
        interfaceId == type (IERC721Metadata). interfaceId;
  return true;
    }

    function balanceof(address owner)public view virtual override returns(uint256){
        require (owner != address (0), "address zero is not valid for owner");

        return _balances[owner];
    }

  function ownerof(uint256 tokenid)public view virtual override returns (address owner){

        owner = _owners[tokenid];

        require(owner !=  address(0),"invalid token ID");

        return owner;
    }

  function name ()public view virtual override returns (string memory){

        return _name;

    }

  function symbol()public view virtual override returns(string memory){
        return _symbol;
    }


    function tokenURI(uint256 tokenid) public view virtual override returns (string memory){

        require(_owners[tokenid] != address(0), "token doesn't exist");

         
        return "";
    }

  function _baaseURI()public view virtual returns(string memory){
        return "";
    }

  function approve(address to, uint256 tokenid) public virtual override{
      address owner = ownerof(tokenid);

      require(to != owner , " do not approve");

      require(
          msg.sender== owner || isapproveForAll(owner , msg.sender),

          "approve caller is not token owner nor approved for all"
      );
  }
  function isapproveForAll(address owner , address operator)public  view virtual override returns(bool){

    return   _operatorApproval[owner][operator];


}

  function setapproveforAll(address operator, bool approved)public virtual override{

  emit ApprovedForall(msg.sender , operator, approved);
}

  function getapproval(uint256 tokenid)public view virtual override returns(address){


    return   _tokenApprovals[tokenid];

}


  function transferfrom(

    address from,

    address to,

    uint256 tokenid
) public virtual override{
require (_isApprovedOrOwner(msg.sender , tokenid), "caller is not token owner norapproved");

_transfer(from , to , tokenid);

}

  function safetransferfrom(
    address from,

    address to ,

    uint256 tokenid

)public virtual override{

    safetransferfrom(from , to , tokenid, "");

}


  function safetransferfrom(
    address from,

    address to,

    uint256 tokenid,

    bytes memory data
) public virtual override{

    require (_isApprovedOrOwner(msg.sender , tokenid),
    "caller is not token owner nor approved");

    _safetransfer(from , to , tokenid , data);

}

  function _safetransfer(

    address from,

    address to,

    uint256 tokenid,

    bytes memory data
)public virtual{

    _transfer(from , to , tokenid);
     
     require(_checkOnERC721Received(from , to , tokenid , data),
     " transfer to non ERC721Receiver implementer");

}

  function _isApprovedOrOwner(address spender, uint256 tokenid) public view virtual returns (bool) {

        address owner = ownerof(tokenid);


        return (spender == owner || isapproveForAll(owner, spender) || getapproval(tokenid) == spender);

}

  function _exists(uint256 tokenid) public view virtual returns (bool) {

        return _owners[tokenid] != address(0);
    }

function mint( address to , uint256 tokenid) public virtual{

     require(to != address(0), "ERC721: mint to the zero address");

     require(!_exists(tokenid), "ERC721: token already minted");

     _balances[to] += 1;

     _owners[tokenid] = to;

     emit Transfer( address(0) , to , tokenid);

     aftertokentransfer(address(0) , to , tokenid);
       }


  function burn(uint256 tokenid)public virtual{

           address owner = ownerof (tokenid);

       beforetokentransfer(owner , address(0) , tokenid);

       delete _tokenApprovals[tokenid];

       _balances[owner]-= 1;

       delete _owners[tokenid];

       emit Transfer(owner , address(0) , tokenid);

       aftertokentransfer(owner , address(0) , tokenid);


       }

        function _transfer(
        address from,
        address to,
        uint256 tokenid
    ) public virtual {
        require( ownerof(tokenid) == from, " transfer from incorrect owner");
        require(to != address(0), " transfer to the zero address");

        beforetokentransfer(from, to, tokenid);

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenid];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenid] = to;

        emit Transfer(from, to, tokenid);

        aftertokentransfer(from, to, tokenid);
    }

   function _requireMinted(uint256 tokenid) public view virtual {

        require(_exists(tokenid), " invalid token ID");

   }

    function _checkOnERC721Received(
        address from,

        address to,

        uint256 tokenid,

        bytes memory data
    ) public returns (bool) {

        if (to.isContract()) {

            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenid, data) returns (bytes4 retval) {

                return retval == IERC721Receiver.onERC721Received.selector;

            } catch (bytes memory reason) {

                if (reason.length == 0) {

                    revert("ERC721: transfer to non ERC721Receiver implementer");

                } else {
                    
                    assembly {

                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function beforetokentransfer(
        address from,

        address to,

        uint256 tokenid
    
    )public virtual{}

    function aftertokentransfer(
        address from,

        address to, 

        uint256 tokenid
    )public virtual {}
}