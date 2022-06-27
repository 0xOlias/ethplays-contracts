// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IBadgeRenderer} from "src/interfaces/IBadgeRenderer.sol";

contract Badge is ERC1155, Owned {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    // /// @dev Renderer contract for on-chain metadata
    IBadgeRenderer public metadata;

    address private royaltyReceiver;
    uint24 private royaltyAmount;

    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    event SetMetadataAddress(address metadata);
    event SetMerkleRoot(uint256 id, bytes32 root);
    event Claim(address account, uint256 id);

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error InvalidToken();
    error AlreadyClaimed();
    error NotEligibleToClaim();
    error NoMetadata();
    error PaymentFailed();
    error NoTokenToBurn();

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /// @dev Require the metadata address to be set
    modifier onlyWithMetadata() {
        if (address(metadata) == address(0)) revert NoMetadata();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /// @param owner The owner of the contract upon deployment
    /// @param _royaltyReceiver Royalty data
    constructor(address owner, address _royaltyReceiver)
        ERC1155()
        Owned(owner)
    {
        royaltyReceiver = _royaltyReceiver;
        royaltyAmount = 640;
    }

    /// @notice Sets the rendering/metadata contract address
    /// @param _metadata The address of the metadata contract
    function setMetadata(IBadgeRenderer _metadata) external onlyOwner {
        metadata = _metadata;
        emit SetMetadataAddress(address(_metadata));
    }

    /// @notice Sets the rendering/metadata contract address
    /// @dev The metadata address construction of baseURI
    /// @param id The token id to set merkleRoot for
    /// @param merkleRoot The merkle root of the claim list
    function setMerkleRoot(uint256 id, bytes32 merkleRoot) external onlyOwner {
        merkleRoots[id] = merkleRoot;
        emit SetMerkleRoot(id, merkleRoot);
    }

    /* ------------------------------------------------------------------------
                                P U R C H A S I N G
    ------------------------------------------------------------------------ */

    /// @notice Mints 1 token of the specified id to the sender
    /// @param id The id of the edition to mint
    /// @param proof Merkle proof to prove address is in tree
    function mintEdition(uint256 id, bytes32[] calldata proof) external {
        if (hasClaimed[id][msg.sender]) {
            revert AlreadyClaimed();
        }

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoots[id], leaf);
        if (!isValidLeaf) {
            revert NotEligibleToClaim();
        }

        hasClaimed[id][msg.sender] = true;
        _mint(msg.sender, id, 1, "");
        emit Claim(msg.sender, 1);
    }

    /* ------------------------------------------------------------------------
                                  E R C - 1 1 5 5
    ------------------------------------------------------------------------ */

    /// @notice Burn a token
    /// @param id The id of the token you want to burn
    function burn(uint256 id) external {
        if (balanceOf[msg.sender][id] == 0) revert NoTokenToBurn();
        _burn(msg.sender, id, 1);
    }

    /// @notice Standard URI function to get the token metadata
    /// @param id The token id to get metadata for
    function uri(uint256 id)
        public
        view
        virtual
        override
        onlyWithMetadata
        returns (string memory)
    {
        return metadata.tokenURI(id);
    }

    /* ------------------------------------------------------------------------
                                  W I T H D R A W
    ------------------------------------------------------------------------ */

    /// @notice Withdraw the contracts ETH balance to the admin wallet
    function withdrawBalance() external {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        if (!success) revert PaymentFailed();
    }

    /// @notice Withdraw all ERC20 tokens for a given token address to the admin wallet
    function withdrawToken(IERC20 tokenAddress) external {
        tokenAddress.transfer(owner, tokenAddress.balanceOf(address(this)));
    }

    /* ------------------------------------------------------------------------
                                 R O Y A L T I E S
    ------------------------------------------------------------------------ */

    /// @notice EIP-2981 royalty standard for on-chain royalties
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 amount)
    {
        receiver = receiver;
        amount = (salePrice * amount) / 10_000;
    }

    /// @notice Update royalty information
    /// @param _royaltyReceiver The receiver of royalty payments
    /// @param _royaltyAmount The royalty percentage with two decimals (10000 = 100)
    function setRoyaltyInfo(address _royaltyReceiver, uint256 _royaltyAmount)
        external
        onlyOwner
    {
        royaltyReceiver = _royaltyReceiver;
        royaltyAmount = uint24(_royaltyAmount);
    }

    /// @dev Extend `supportsInterface` to support EIP-2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // EIP-2981 = bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }
}
