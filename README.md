# Ponder
zora api hackathon submission

My submission is a lightweight, native objective-c client to consume GraphQL output from the ZORA API.

This is the bare minimum necessary to interact with the ZORA API using obj-c without third party libraries or frameworks.

A demonstration of the capabilities takes a contract address as input, and shows various stats such as the contract name, symbol, total supply, total number of owners, and a breakdown of the top 20 owners.

 Additionally, a more in-depth demonstration of the analytics capabilities made possible with the ZORA API can be found with the “Get Top Collections” feature (output is currently logged to console rather than displayed in GUI), which processes the wallets for all token holders, and generates the top 10 shared collections across those wallets. This could be useful for community building, outreach, marketing, and tracking emerging trends in the NFT ecosystem. (Please note that this feature takes awhile to run, and these calculations could be performed much more efficiently on the backend. Perhaps some convenience accuser methods from the ZORA team in the future for some of this type of data?)<img width="1012" alt="Screen Shot 2022-06-13 at 10 22 03 AM" src="https://user-images.githubusercontent.com/120711/173393591-d3fc317e-5955-4d2d-b731-9f66bafb08f5.png">
<img width="1012" alt="Screen Shot 2022-06-13 at 10 21 38 AM" src="https://user-images.githubusercontent.com/120711/173393596-f1891c5c-e8a3-44ff-b6f3-bdb602abdff8.png">
<img width="462" alt="Screen Shot 2022-06-13 at 10 50 38 AM" src="https://user-images.githubusercontent.com/120711/173393789-d17f6edb-7a3a-457a-b907-7228ef7e10bc.png">
