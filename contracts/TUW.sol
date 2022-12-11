// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "./utilities/EnumDeclaration.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TheUnchainedWolfs is ERC721, ERC2981, Pausable, Ownable, ERC721Burnable, EIP712, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    bool public whitelistMintEnabled = false;

    string public hiddenMetadataUri;
    string public uriSuffix = '.json';
    string public uriPrefix = '';
    bool public revealed = false;
    uint256 public maxSupply;

    address public constant daoAddress = 0xa33CF97c010F9E4bB06d0851E5BC3a6C02F85739;

    bool public payChainToken = true;
    IERC20 public payableToken;
    //WOLF Collection
     mapping (Collection=> Chest)  public WolfCollection;

    constructor()
        ERC721("The Unchained Wolfs", "TUW")
        EIP712("The Unchained Wolfs", "1")
    {
      WolfCollection[Collection.RARE_WOLF]=Chest(1,1,6000,0.1 ether,false);
      WolfCollection[Collection.EPIC_WOLF]= Chest(6001,6001,9000,0.2 ether,false);
      WolfCollection[Collection.LEGENDARY_WOLF]= Chest(9001,9001,10000,0.3 ether,false);
      maxSupply =10000;
      setRoyaltyInfo(msg.sender, 1000);
      pause();
    }

   
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


     //***********************************************************/
    //*************************MINT TUW FUNCTIONS****************/
    //***********************************************************/
    function mintPriceCompliance(uint256 cost)private returns (bool) {
      if(payChainToken){
      require(msg.value >= cost , 'Insufficient funds!');
      return true;
      }
      if(!payChainToken){
        require(cost > GetAllowance(), "Please approve tokens before transferring");
        return AcceptPayment(cost);
      }
      return false;
  }

    function publicMint(Collection _collection) public payable whenNotPaused {
      Chest storage chest = WolfCollection[_collection];
      require(chest.Status == true,"Chest is not enable");
      require(chest.CurrentId <= chest.End, "All NFT in this Chest are minted");
      require(msg.sender == tx.origin, "Smart contracts can't Mint");
      if( mintPriceCompliance(chest.Cost)){
             _mint(msg.sender, chest.CurrentId);         
        unchecked {
            chest.CurrentId++;
                }}
               
    }

    function whitelistMint(Collection _collection, bytes32[] calldata _merkleProof) public payable {
    Chest storage chest = WolfCollection[_collection];
    require(chest.Status == true,"Chest is not enable");
    require(chest.CurrentId <= chest.End, "All NFT in this Chest are minted");
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    whitelistClaimed[_msgSender()] = true;
    if( mintPriceCompliance(chest.Cost)){
             _mint(msg.sender, chest.CurrentId);         
        unchecked {
            chest.CurrentId++;
                }}
  }


    //***********************************************************/
    //***************************PREFIX URI TOKEN****************/
    //***********************************************************/

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  

    //***********************************************************/
    //***************************Admin Functions****************/
    //**********************************************************/

        function safeMint(address to, Collection _collection) public onlyOwner {
        Chest storage chest = WolfCollection[_collection];
        require(chest.CurrentId <= chest.End, "All NFT in this Chest are minted");
        _mint(to, chest.CurrentId);         
        unchecked {
            chest.CurrentId++;
                }
    }

    function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }


  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setPaymentToken(address token) public onlyOwner {
        payableToken = IERC20(token);
    }

  function withdraw() public onlyOwner nonReentrant{
    uint256 balance = address(this).balance;
    // =============================================================================
    (bool dao, ) = payable(daoAddress).call{value: balance * 30 / 100}('Wolf DAO');
    require(dao);
    // =============================================================================
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

    //***********************************************************/
    //***************************Payable Functions***************/
    //**********************************************************/
    function AcceptPayment(uint256 _tokenamount) public returns(bool) 
    { 
       payableToken.transfer(address(this), _tokenamount);
       return true;
   }

   function GetAllowance() public view returns(uint256){
       return payableToken.allowance(msg.sender, address(this));
   }


    //***********************************************************/
    //***************************Royalty Functions***************/
    //**********************************************************/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721,ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner{
      _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }
}

