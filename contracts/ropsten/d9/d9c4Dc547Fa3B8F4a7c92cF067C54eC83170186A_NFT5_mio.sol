/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

pragma solidity 0.8.14 ; 


contract NFT5_mio {
    address payable public creatore ;
    address payable public artista ;
    address payable public attuale_proprietario ;
    mapping(address => uint256) public storia ; 
    uint256 public  prezzo ; 
    uint256 public  minimo_incremento_default ;
        address payable public chi_vuole_comprare ;
        bool public opera_vendibile ; 

/*
        event Cambio_prezzo_0( uint256 prezzo ) ; 
         event Cambio_vendibilita_0( bool opera_vendibile ) ;
         event Cambio_proprietario_0 ( address attuale_proprietario  , uint256 prezzo ) ;  
*/

constructor( uint256 prezzo_da_constructor ){
    creatore = payable (msg.sender) ;
    artista = payable(0x618665a40d6b1d2B3386c5C5472471f8B77B97ed) ;  //Brave Account_1 
   // minimo_incremento_default =  2*10**16 ;  // 1eth = 10**18
    attuale_proprietario = payable(0x618665a40d6b1d2B3386c5C5472471f8B77B97ed) ; //uguale ad artista all inizio
    prezzo = prezzo_da_constructor ; //  BigInt(2*10**16) ; 
    opera_vendibile = true ; 
}


modifier controllo_1() {
    require ( msg.sender == attuale_proprietario || msg.sender == creatore , 'only current owner can perform this task'  ) ;
    _;
}

/*   NON FUNZIONANO OPPURE DA PROVARE 
function  cambia_vendibilita() public controllo_1() returns(bool){
    opera_vendibile  = !opera_vendibile ; 
    emit Cambio_vendibilita_0(opera_vendibile) ; 
    return true ; 
}

function cambio_prezzo_vendita() public payable controllo_1() returns(bool){
prezzo = msg.value ; 
emit Cambio_prezzo_0(prezzo) ; 
return true ; 
}

function comprare() public payable returns (bool){
    uint256 prezzo_test = 3*10**16 ; 
    require(opera_vendibile , 'the item is not buyable') ;
    require( msg.sender.balance > prezzo , "not enough founds to buy " ) ; 
  //  (bool pagamento_riuscito , ) = payable(attuale_proprietario).call{value:prezzo*9/10 ,gasLimit : 2099}("cosa sia quesa stringa ?")  ; 
  // (bool pagamento_riuscito_2 , ) = payable(creatore).call{value : prezzo/10  ,gasLimit: 2099}("cosa sia quesa stringa  --- b  ?")  ;
  // require( pagamento_riuscito && pagamento_riuscito_2 , " qualcosa andato storto ") ;
    (bool pagamento_riuscito_3 , ) = payable( msg.sender ).call{value : prezzo_test  }("cosa sia quesa stringa  --- c  ?")  ;
 require(  pagamento_riuscito_3 , " qualcosa andato storto __ HO TOLTO I DECIMALI  ") ;
     
    attuale_proprietario = payable(msg.sender) ; 
    prezzo = prezzo * 2 ; 
    emit Cambio_proprietario_0( attuale_proprietario ,    prezzo_test ) ;
    return true ; 
} 

*/



// sotto funzionano
function getPrice() public view returns (uint256) {
    return prezzo ; 
} 

function getOwner() public view returns (address) {
    return attuale_proprietario ; 
} 

function getCreatore() public view returns (address) {
    return creatore ; 
} 


 // event LogBid(address indexed _highestBidder , uint256 _highestBid) ;

function comprare() public payable   returns (bool) {
   uint256 bidAmount =  msg.value;  //forse giä  sottinteso con payable che sta pagando
   require(bidAmount > 7 , 'Bid error: Make a higher Bid.');  //PENSO CHE MISUARA SIA IIN WEI

   attuale_proprietario = payable(msg.sender) ;
   prezzo = prezzo +  1*10**16 ;  // sono solo dei numeri ,  unita misura sono i wei

   //se noti non cé la funzione che spedisce al proprietario precedente 
   // i vecchi fondi 
 //  uint256 tempp = bidAmount ;
 //  bidAmount = 0 ;


// questo funziona !!  non so se il tranfer limit gas 2300 ,  sia 100gwei  
//  quindi 0.00023 ETH 
 //  payable(creatore).transfer( msg.value );
  
  // 2 data , ritorna dal fallback value
   (bool success ,   ) = payable(creatore).call{value : msg.value ,  gas:21000}("") ; 
      require(success , "REFUND ... Withdrawal failed  ");


  // (bool success, ) = payable(creatore).call{value:bidAmount}("") ; 
// require(success , "REFUND ... Withdrawal failed  ");
   
   return true;
 }


}