import { expect } from "chai";
import { ethers } from "hardhat";

describe("Test 721WCK", function () {
    let owner, userA;
    let kittyCoreTest, wCKNFT;
    let tx, receipt;

    beforeEach(async function () {
        [owner,userA] = await ethers.getSigners();
        const KittyCoreTest = await ethers.getContractFactory("KittyCoreTest");
        const WrappedCryptoKitties = await ethers.getContractFactory("WrappedCryptoKitties");
        

        kittyCoreTest = await KittyCoreTest.deploy();
        wCKNFT = await WrappedCryptoKitties.deploy(kittyCoreTest.address, "Wrapped CryptoKitties", "721WCK");
    })

    describe("wrap & unwrap ", function () {
        it("success wrap &  unwrap", async function () {
            const id =  3001;
            const gen = 1;
            await kittyCoreTest.mintGreaterThan3000(id, gen,true);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);
    
            await kittyCoreTest.approve(wCKNFT.address, id);

            await wCKNFT.wrap(id);

            expect(await wCKNFT.ownerOf(id)).equal(owner.address);
            expect(await kittyCoreTest.ownerOf(id)).equal(wCKNFT.address);

            await wCKNFT.unwrap(id);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);

        });              
    });

    describe("wrap , unwrap failed", function () {

        it("not owner", async function () {
            const id1 =  3002;
            const id2 =  3003;
            const gen = 1;
            await kittyCoreTest.mintGreaterThan3000(id1, gen,true);
            await kittyCoreTest.connect(userA).mintGreaterThan3000(id2, gen,true);
            expect(await kittyCoreTest.ownerOf(id1)).equal(owner.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(userA.address);
    
            await expect(wCKNFT.wrap(id2)).to.be.revertedWith("not owner");

            await expect(wCKNFT.wrap(id1)).to.be.revertedWith("not approve");

            await kittyCoreTest.approve(wCKNFT.address, id1);
            await wCKNFT.wrap(id1);

            await kittyCoreTest.connect(userA).approve(wCKNFT.address, id2);
            await wCKNFT.connect(userA).wrap(id2);

            
            await expect(wCKNFT.unwrap(id2)).to.be.revertedWith("not owner");

        });
        
    });

    describe("batch wrap & batch unwrap ", function () {
        it("success wrap &  unwrap", async function () {
            const id1 =  3001;
            const id2 =  3002;
            const gen = 1;
            await kittyCoreTest.mintGreaterThan3000(id1, gen,true);
            await kittyCoreTest.approve(wCKNFT.address, id1);

            

            await wCKNFT.batchWrap([id1], owner.address);

            expect(await wCKNFT.ownerOf(id1)).equal(owner.address);
            expect(await kittyCoreTest.ownerOf(id1)).equal(wCKNFT.address);

            await wCKNFT.batchUnwrap([id1], owner.address);
            expect(await kittyCoreTest.ownerOf(id1)).equal(owner.address);


            await kittyCoreTest.mintGreaterThan3000(id2, gen,true);
            await kittyCoreTest.approve(wCKNFT.address, id2);
            await wCKNFT.batchWrap([id2], userA.address);

            expect(await wCKNFT.ownerOf(id2)).equal(userA.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wCKNFT.address);

            await wCKNFT.connect(userA).batchUnwrap([id2], owner.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(owner.address);
        });              
    });

    describe("supportsInterface", function () {
        it("supportsInterface", async function () {

            // EIP-2981
            expect(await wCKNFT.supportsInterface('0x2a55205a')).equal(true);
    
            // EIP-721
            expect(await wCKNFT.supportsInterface('0x80ac58cd')).equal(true);            
        });              
    });

    describe("owner function", function () {
        it("updateRoyaltyInfo", async function () {

            let receiver_ = userA.address;
            let royaltyFee_  = 0;
            let tokenId = 1;
            let price = 10000;
            const denominator = 1000;
            await wCKNFT.updateRoyaltyInfo(receiver_, royaltyFee_);
    
            let result  =  await wCKNFT.royaltyInfo(tokenId, price);
            expect(result[0]).equal(receiver_);
            expect(result[1]).equal(price * royaltyFee_ / denominator );
    
            royaltyFee_ = 10;
            await wCKNFT.updateRoyaltyInfo(receiver_, royaltyFee_);
            result  =  await wCKNFT.royaltyInfo(tokenId, price);
            expect(result[0]).equal(receiver_);
            expect(result[1]).equal(price * royaltyFee_ / denominator );
        });
        
        it("setTokenURIContract", async function () {

            const OffChainTokenURI = await ethers.getContractFactory("OffChainTokenURI");
            const OFF_CHAIN_BASE_URI =  "https://api.cryptokitties.co/tokenuri/";

            const offChainTokenURI = await OffChainTokenURI.deploy(OFF_CHAIN_BASE_URI);
            await wCKNFT.setTokenURIContract(offChainTokenURI.address);
    
            let uriContract  =  await wCKNFT.getTokenURIContract();
            expect(uriContract).equal(offChainTokenURI.address);
           
            let tokenURI = await wCKNFT.tokenURI(1);
    
            expect(tokenURI).equal("https://api.cryptokitties.co/tokenuri/1");

            
            const OFF_CHAIN_BASE_URI2 =  "https://api2.cryptokitties.co/tokenuri/";

            await offChainTokenURI.setBaseURI(OFF_CHAIN_BASE_URI2);
    
            tokenURI = await wCKNFT.tokenURI(1);
    
            expect(tokenURI).equal("https://api2.cryptokitties.co/tokenuri/1");
        });
    });
});

