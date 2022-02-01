/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity  0.8.7;


    interface show{
     event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    }

    contract ERC721 is show{

        string     private  _name;
        string     private  _symbol;
       

        constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
     }




   
    mapping (address =>uint) _balances;
    mapping (uint =>address) _owners;





        function _safeMint(
        address to,
        uint256 tokenId
       
    ) internal virtual {
        _mint(to, tokenId);
  
    }


    
       function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }


        function _mint(address to, uint256 tokenid) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenid), "ERC721: token already minted");

       

        _balances[to] += 1;
        _owners[tokenid] = to;

        emit Transfer(address(0), to, tokenid);
    }

        function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

       

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

   

      
    }

        function balanceOf(address owner) public view virtual  returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

        function ownerOf(uint256 tokenId) public view virtual  returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }


    
}




        contract DOCTOR is ERC721{ 

        mapping(address => mapping(address => uint256)) private _allowances1;

        mapping(address => uint256) private _balances1;
     
    
        // string     private    _name;
        // string     private    _symbol;

        uint       private    _tokenid=1;
        uint256    public     _maxSupply =10000000;
        string    private    _baseURI;
       
 
 



        constructor(string memory baseURI) ERC721("name", "symbol")  {
        setBaseURI(baseURI);
    }

     function setBaseURI(string memory baseURI) public  {
        _baseURI = baseURI;
    }
    





 
        function transfer(address recipient, uint256 amount) public virtual  returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }



        function mint(uint quantity) public payable  {

        require(quantity > 0, "Number of tokens can not be less than or equal to 0");
        require(quantity+totalsupply()<=_maxSupply,"public sale ended all tokens have been minted");
    
                for(uint i ;i < quantity;i++){
               _safeMint(msg.sender,totalsupply());
               _tokenid++;

           }
            
       }

          function totalsupply()public view returns(uint){
          return _tokenid;
        }


}