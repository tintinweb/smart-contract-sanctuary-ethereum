// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "linked_list.sol";
import "IERC20.sol";

contract TokenTrading{
    event offerEvent(uint256 offer_id,address token_address, address seller, uint256 tokens,uint256 price);
    event withdrawEvent(uint256 offer_id,address token_address,uint256 tokens);
    event buyEvent(uint256 offer_id,address token_address,uint256 tokens,uint256 price,address from,address to);

    LinkedList offers=new LinkedList();

    address[] users;
    mapping(address=>bool) isUser;

    struct Quote{
        uint256 offerId;
        uint256 tokens;
    }
    struct Info{
        address addr;
        uint256 owned;
        uint256 offered;
    }

    modifier is_transferrable(address _tok_addr,address _from,uint256 _tokens){
        IERC20 token_interface=IERC20(_tok_addr);
        require(token_interface.balanceOf(_from)>=_tokens,"Not enough tokens owned");
        uint256 token_allowance=token_interface.allowance(_from,address(this));
        require(token_allowance>=_tokens,"Not sufficient allowance tokens. Please grant tokens approval");
        _;
    }

    function offer(address _tok_addr,uint256 _tokens,
                   uint256 _price_in_wei) public is_transferrable(_tok_addr,
                                                                  msg.sender,
                                                                  offers.user2offered(_tok_addr,msg.sender)+_tokens){
        require(_tokens>0,"Invalid number of tokens");
        if (!isUser[msg.sender]){
            users.push(msg.sender);
            isUser[msg.sender]=true;
        }
        uint256 index=offers.insert(_tok_addr,payable(msg.sender),_price_in_wei,_tokens);
        emit offerEvent(index,_tok_addr,msg.sender,_tokens,_price_in_wei);
    }

    function withdraw(address _tok_addr,uint256 _offerId,uint256 _tokens) public{
        require(_tokens>0,"Invalid number of tokens");
        require(offers.isOfferId(_tok_addr,_offerId),"OfferId does not exist");
        (LinkedList.Data memory _offer,)=offers.retrieve(_tok_addr,_offerId);
        require(payable(msg.sender)==_offer.seller,"OfferId does not belong to the user");
        require(_tokens<=_offer.tokens,"Not enough tokens in the given offerId");
        offers.remove(_tok_addr,_offerId,_tokens);
        emit withdrawEvent(_offerId,_tok_addr,_tokens);
    }

    function get_token_offers(address _tok_addr) public view returns(LinkedList.Data[] memory){
        return offers.token_data(_tok_addr);
    }

    function get_user_tokens(address _user) public view returns(Info[] memory){
        Info[] memory info_array=new Info[](offers.tokens_length());
        for (uint256 i=0;i<offers.tokens_length();i++){
            IERC20 token_interface=IERC20(offers.tokens(i));
            info_array[i]=Info({addr:offers.tokens(i),
                                owned:token_interface.balanceOf(_user),
                                offered:offers.user2offered(offers.tokens(i),_user)});
        }
        return info_array;
    }

    function get_token_users(address _tok_addr) public view returns(Info[] memory){
        Info[] memory info_array=new Info[](users.length);
        IERC20 token_interface=IERC20(_tok_addr);
        for (uint256 i=0;i<users.length;i++){
            info_array[i]=Info({addr:users[i],
                                owned:token_interface.balanceOf(users[i]),
                                offered:offers.user2offered(_tok_addr,users[i])});
        }
        return info_array;
    }

    function get_supply(address _tok_addr) public view returns(uint256,uint256){
        return (offers.token_count(_tok_addr),offers.average_price(_tok_addr));
    }

    function request_quote(address _tok_addr,uint256 _tokens) public returns (uint256,Quote[] memory){    
        require(_tokens<=offers.token_count(_tok_addr),"Not enough tokens available");
        uint256 index=offers.best_index(_tok_addr);
        uint256 index_count=offers.index_count(_tok_addr);
        uint256 buyable;
        uint256 quote;
        Quote[] memory offer_array=new Quote[](index_count);
        uint256 size=0;
        for (uint256 i=0;buyable<_tokens;i++){
            (LinkedList.Data memory _offer,uint256 next)=offers.retrieve(_tok_addr,index);
            if (buyable+_offer.tokens<=_tokens){
                quote+=_offer.price*_offer.tokens;
                offer_array[i]=Quote({offerId:index,tokens:_offer.tokens});
                size+=1;
                buyable+=_offer.tokens;
            }
            else{
                quote+=(_tokens-buyable)*_offer.price;
                offer_array[i]=Quote({offerId:index,tokens:_tokens-buyable});
                size+=1;
                buyable=_tokens;
            }
            index=next;
        }
        Quote[] memory offer_array_trunc=new Quote[](size);
        for (uint256 i=0;i<size;i++){
            offer_array_trunc[i]=offer_array[i];
        }

        return (quote,offer_array_trunc);
    }

    function buy(address _tok_addr,uint256 _tokens) external payable{
        (uint256 quote,Quote[] memory offer_array)=request_quote(_tok_addr,_tokens);
        require(msg.value>=quote,"Sent value is less than quote price, spend more ethers!");
        uint256 cost;
        IERC20 token_interface=IERC20(_tok_addr);
        for (uint256 i=0;i<=offer_array.length-1;i++){
            uint256 offerId=offer_array[i].offerId;
            uint256 tokens=offer_array[i].tokens;
            (LinkedList.Data memory _offer,)=offers.retrieve(_tok_addr,offerId);
            cost+=buy_offerId(_tok_addr,_offer,tokens,msg.sender,token_interface);
        }
        if (cost<msg.value){
            payable(msg.sender).transfer(msg.value-cost);
        }
    }

    function buy_offerId(address _tok_addr,LinkedList.Data memory _offer,
                         uint256 _tokens,address _to,
                         IERC20 _token_interface) internal is_transferrable(_tok_addr,
                                                                            _offer.seller,
                                                                            _tokens) returns(uint256){
        uint256 cost=_offer.price*_tokens;
        _offer.seller.transfer(cost);
        offers.remove(_tok_addr,_offer.offerId,_tokens);
        if (!isUser[_to]){
            users.push(_to);
            isUser[_to]=true;
        }
        _token_interface.transferFrom(_offer.seller,_to,_tokens);
        emit buyEvent(_offer.offerId,_tok_addr,_tokens,_offer.price,_offer.seller,_to);
        return cost;
    }

    receive() external payable{

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LinkedList{
    mapping(address=>mapping(uint256=>Element)) linked;
    
    mapping(address=>uint256) next_index;
    uint256 end_index=0;

    address[] public tokens;                        // token_addresses
    mapping(address=>bool) public isToken;
    mapping(address=>uint256) token2index;

    mapping(address=>uint256) public best_index;
    mapping(address=>uint256) public index_count;
    mapping(address=>uint256) public average_price;
    mapping(address=>uint256) public token_count;
    mapping(address=>mapping(uint256=>bool)) public isOfferId;
    mapping(address=>mapping(address=>uint256)) public user2offered;

    struct Data{
        uint256 offerId;
        address payable seller;
        uint256 price;
        uint256 tokens;
    }

    struct Element{
        Data data;
        uint256 next;
    }

    function add_token(address _tok_addr) internal{
        if (!isToken[_tok_addr]){
            tokens.push(_tok_addr);
            token2index[_tok_addr]=tokens.length-1;
            isToken[_tok_addr]=true;

            next_index[_tok_addr]=1;
            best_index[_tok_addr]=end_index;
            index_count[_tok_addr]=0;
        }
    }

    function del_token(address _tok_addr) internal{
        if (token_count[_tok_addr]==0){
            tokens[token2index[_tok_addr]]=tokens[tokens.length-1];
            tokens.pop();
            delete token2index[_tok_addr];
            delete isToken[_tok_addr];

            delete next_index[_tok_addr];
            delete best_index[_tok_addr];
            delete index_count[_tok_addr];
        }
    } 

    function retrieve(address _tok_addr,uint256 _index) public view returns(Data memory,uint256){
        return (linked[_tok_addr][_index].data,linked[_tok_addr][_index].next);
    }

    function tokens_length() public view returns(uint256){
        return tokens.length;
    }

    function token_data(address _tok_addr) public view returns(Data[] memory){
        uint256 index=best_index[_tok_addr];
        Data[] memory data_array=new Data[](index_count[_tok_addr]);
        for (uint256 i=0;i<index_count[_tok_addr];i++){
            data_array[i]=linked[_tok_addr][index].data;
            index=linked[_tok_addr][index].next;
        }
        return data_array;
    }
    
    function position(address _tok_addr,uint256 _price) internal view returns(uint256,uint256){
        uint256 i=best_index[_tok_addr];
        uint256 i_pre=end_index;
        if (i!=end_index){
            Element memory eli=linked[_tok_addr][i];
            while (eli.data.price<=_price){
                i_pre=i;
                i=eli.next;
                if (i==end_index){
                    break;
                }
                else{
                    eli=linked[_tok_addr][i];
                }
            }
        }
        return (i_pre,i);
    }

    function previous(address _tok_addr,uint256 _index) internal view returns(uint256){
        uint256 i=best_index[_tok_addr];
        uint256 i_pre=end_index;
        if (i!=end_index){
            Element memory eli=linked[_tok_addr][i];
            while (i!=_index){
                i_pre=i;
                i=eli.next;
                if (i==end_index){
                    break;
                }
                else{
                    eli=linked[_tok_addr][i];
                }
            }
        }
        return i_pre;
    }

    function insert(address _tok_addr,address payable _seller,uint256 _price,uint256 _tokens) public returns(uint256){
        add_token(_tok_addr);
        
        (uint256 i_pre, uint256 i)=position(_tok_addr,_price);

        Data memory data;
        data.offerId=next_index[_tok_addr];
        data.seller=_seller;
        data.price=_price;
        data.tokens=_tokens;
        Element memory el=Element({data:data,next:i});

        linked[_tok_addr][next_index[_tok_addr]]=el;
        if (i_pre!=end_index){
            linked[_tok_addr][i_pre].next=next_index[_tok_addr];
        }
        if (best_index[_tok_addr]==end_index || 
            _price<linked[_tok_addr][best_index[_tok_addr]].data.price){
            best_index[_tok_addr]=next_index[_tok_addr];
        }
        uint256 new_index=next_index[_tok_addr];
        // average_price[_tok_addr]=((average_price[_tok_addr]*token_count[_tok_addr])+(_price*_tokens))/(token_count[_tok_addr]+_tokens);
        // token_count[_tok_addr]+=_tokens;
        update_supply(_tok_addr,next_index[_tok_addr],int256(_tokens));
        isOfferId[_tok_addr][next_index[_tok_addr]]=true;
        // user2offered[_tok_addr][_seller]+=_tokens;

        next_index[_tok_addr]+=1;
        index_count[_tok_addr]+=1;
        
        return new_index;
    }

    function remove(address _tok_addr,uint256 _offerId,uint256 _tokens) public{
        uint256 pre_tokens=linked[_tok_addr][_offerId].data.tokens;
        // uint256 price=linked[_tok_addr][_offerId].data.price;
        // address seller=linked[_tok_addr][_offerId].data.seller;
        if (_tokens!=pre_tokens){
            linked[_tok_addr][_offerId].data.tokens=pre_tokens-_tokens;
        }
        else{
            uint256 index_pre=previous(_tok_addr,_offerId);
            if (index_pre!=end_index){
                linked[_tok_addr][index_pre].next=linked[_tok_addr][_offerId].next;
            }
            else{
                best_index[_tok_addr]=linked[_tok_addr][_offerId].next;
            }
            delete linked[_tok_addr][_offerId];
            delete isOfferId[_tok_addr][_offerId];
            index_count[_tok_addr]-=1;
        }
        // average_price[_tok_addr]=((average_price[_tok_addr]*token_count[_tok_addr])-(price*_tokens))/(token_count[_tok_addr]-_tokens);
        // token_count[_tok_addr]-=_tokens;
        // user2offered[_tok_addr][seller]-=_tokens;
        update_supply(_tok_addr,_offerId,-int256(_tokens));
        del_token(_tok_addr);
    }

    function update_supply(address _tok_addr,uint256 _offerId,int256 _tokens) internal{
        uint256 price=linked[_tok_addr][_offerId].data.price;
        address seller=linked[_tok_addr][_offerId].data.seller;

        uint256 net_price=uint256(int256(average_price[_tok_addr]*token_count[_tok_addr])+int256(price)*_tokens);
        uint256 net_tokens=uint256(int256(token_count[_tok_addr])+_tokens);
        uint256 user_tokens=uint256(int256(user2offered[_tok_addr][seller])+_tokens);
        
        if (net_tokens!=0){
            average_price[_tok_addr]=net_price/net_tokens;
            token_count[_tok_addr]=net_tokens;

        }
        else{
            delete average_price[_tok_addr];
            delete token_count[_tok_addr];

        }
        if (user_tokens!=0){
            user2offered[_tok_addr][seller]=user_tokens;
        }
        else{
            delete user2offered[_tok_addr][seller];
        }


    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}