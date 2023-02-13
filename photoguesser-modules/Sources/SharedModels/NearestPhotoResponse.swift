import Foundation

// MARK: - NearestPhotosResponse
public struct NearestPhotosResponse: Codable {
	public let result: Result
	public let rid: String
	
	public init(result: Result, rid: String) {
		self.result = result
		self.rid = rid
	}
}

// MARK: - Result
public struct Result: Codable {
	public let photos: [Photo]
	
	public init(photos: [Photo]) {
		self.photos = photos
	}
}

// MARK: - Photo
public struct Photo: Codable {
	public let s, cid: Int
	public let file, title: String
	public let dir: String?
	public let geo: [Double]
	public let year: Int
	public let ccount: Int?
	
	init(
		s: Int,
		cid: Int,
		file: String,
		title: String,
		dir: String?,
		geo: [Double],
		year: Int,
		ccount: Int?
	) {
		self.s = s
		self.cid = cid
		self.file = file
		self.title = title
		self.dir = dir
		self.geo = geo
		self.year = year
		self.ccount = ccount
	}
}

/*
 {
 "result": {
 "photos": [
 {
 "s": 5,
 "cid": 449459,
 "file": "t/t/m/ttmrs80811yfro4md7.jpeg",
 "title": "View of the Marin Tower of the Golden Gate Bridge under construction",
 "dir": "nw",
 "geo": [
 37.82287,
 -122.474985
 ],
 "year": 1934
 },
 {
 "cid": 269502,
 "file": "l/f/2/lf2pu8mk8wf4chvpix.jpg",
 "s": 5,
 "year": 1955,
 "title": "Aerial view of the Golden Gate Bridge with seagull",
 "dir": "w",
 "geo": [
 37.814496,
 -122.468926
 ]
 },
 {
 "cid": 424582,
 "file": "0/g/y/0gyilodb8u3d92zcll.jpg",
 "s": 5,
 "title": "USAAF B-17 Flying Fortress Over Golden Gate Bridge",
 "year": 1944,
 "dir": "nw",
 "geo": [
 37.824565,
 -122.475821
 ],
 "ccount": 2
 },
 {
 "s": 5,
 "cid": 449475,
 "file": "t/s/d/tsda7z1skar3kl3isk.jpeg",
 "title": "Construction of the Golden Gate Bridge with a view of the catwalks being placed under the cables",
 "dir": "s",
 "geo": [
 37.819437,
 -122.478411
 ],
 "year": 1936
 },
 {
 "s": 5,
 "cid": 449471,
 "file": "g/r/h/grh4nvjmieg2p1xj55.jpeg",
 "title": "View from the middle of Golden Gate Bridge under construction",
 "year": 1935,
 "dir": "s",
 "geo": [
 37.819988,
 -122.478587
 ]
 },
 {
 "s": 5,
 "cid": 1446865,
 "file": "3/d/l/3dlc0xkhwhoqq6xkyv.png",
 "title": "Unfinished Golden Gate Bridge",
 "geo": [
 37.820175,
 -122.478686
 ],
 "year": 1935
 },
 {
 "s": 5,
 "cid": 449477,
 "file": "2/d/v/2dvd0975xm279l6q78.jpeg",
 "title": "Men on the catwalks working on the cables",
 "year": 1935,
 "dir": "e",
 "geo": [
 37.816683,
 -122.478371
 ]
 },
 {
 "s": 5,
 "cid": 551764,
 "file": "w/6/e/w6eu707c7be9s7ynzo.jpg",
 "title": "Under the Golden Gate Bridge",
 "dir": "n",
 "geo": [
 37.815818,
 -122.478075
 ],
 "year": 1951,
 "ccount": 1
 },
 {
 "cid": 211178,
 "file": "e/y/5/ey52lf928iynoto16c.jpg",
 "s": 5,
 "year": 1935,
 "title": "Waiting on Catwalk",
 "dir": "e",
 "geo": [
 37.81603,
 -122.478257
 ]
 },
 {
 "s": 5,
 "cid": 754934,
 "file": "9/x/d/9xdwuyc0es6xqjcg74.jpg",
 "title": "On the day of the 50th anniversary of the opening of the Golden Gate bridge",
 "year": 1987,
 "dir": "n",
 "geo": [
 37.82348,
 -122.47874
 ]
 },
 {
 "s": 5,
 "cid": 550629,
 "file": "u/e/c/uecur9ngenrxqvgy9q.jpg",
 "title": "Golden Gate Bridge",
 "dir": "s",
 "geo": [
 37.819308,
 -122.480135
 ],
 "year": 1985
 },
 {
 "s": 5,
 "cid": 449464,
 "file": "x/i/q/xiqbofmzy0mvelui57.jpeg",
 "title": "Riveters at work in cages on the Golden Gate Bridge's South Tower",
 "year": 1935,
 "geo": [
 37.814178,
 -122.477517
 ],
 "dir": "sw"
 },
 {
 "cid": 191516,
 "file": "j/y/s/jys44e853vpwec715v.jpg",
 "s": 5,
 "year": 1935,
 "title": "Golden Gate Bridge construction",
 "dir": "se",
 "geo": [
 37.814081,
 -122.477774
 ]
 },
 {
 "s": 5,
 "cid": 449473,
 "file": "o/2/k/o2kffst782q4phmsep.jpeg",
 "title": "Workmen on the Golden Gate Bridge's South Tower",
 "year": 1935,
 "geo": [
 37.813988,
 -122.477703
 ]
 },
 {
 "cid": 191515,
 "file": "c/q/d/cqdnqovd9c36fonrqb.jpg",
 "s": 5,
 "year": 1934,
 "title": "Golden Gate Bridge construction",
 "dir": "n",
 "geo": [
 37.81403,
 -122.477763
 ]
 },
 {
 "s": 5,
 "cid": 449472,
 "file": "g/2/0/g20ziuchkg4ya1qs6t.jpeg",
 "title": "A worker running up one of the catwalks being built for the construction of the cable of the Golden Gate Bridge",
 "dir": "n",
 "geo": [
 37.814242,
 -122.478053
 ],
 "year": 1935
 },
 {
 "cid": 211183,
 "file": "u/z/3/uz3xjx6jkp9efqvk5j.jpg",
 "s": 5,
 "year": 1935,
 "title": "Catwalk and Marin Tower",
 "dir": "n",
 "geo": [
 37.814021,
 -122.47786
 ]
 },
 {
 "s": 5,
 "cid": 905228,
 "file": "c/x/l/cxlg47y6m8bwvvtb8z.jpg",
 "title": "On the Golden Gate Bridge",
 "dir": "e",
 "geo": [
 37.824768,
 -122.479019
 ],
 "year": 1991
 },
 {
 "s": 5,
 "cid": 449479,
 "file": "4/4/f/44fbrwhejp67oxxi90.jpeg",
 "title": "High-angle view of traffic and pedestrians using the Golden Gate Bridge",
 "dir": "n",
 "geo": [
 37.814005,
 -122.477899
 ],
 "year": 1937
 },
 {
 "s": 5,
 "cid": 449476,
 "file": "b/5/y/b5y0ngpxrmrbs0l9uz.jpeg",
 "title": "Chief Engineer of National Parks Frank Kettredge with his chief counsel George H. Harlan on the Golden Gate bridge",
 "year": 1935,
 "dir": "n",
 "geo": [
 37.814064,
 -122.478025
 ]
 },
 {
 "s": 5,
 "cid": 449474,
 "file": "1/k/k/1kkubqnho6kdtlbwec.jpeg",
 "title": "A construction worker stands at one end of the catwalks that span the Golden Gate between the two towers",
 "year": 1935,
 "dir": "n",
 "geo": [
 37.814047,
 -122.478026
 ]
 },
 {
 "cid": 210887,
 "file": "7/u/y/7uy5ybxzmeeg58xz7g.jpg",
 "s": 5,
 "year": 1934,
 "title": "Signal Man",
 "dir": "",
 "geo": [
 37.813852,
 -122.47788
 ],
 "ccount": 1
 },
 {
 "s": 5,
 "cid": 449462,
 "file": "1/z/z/1zzc9agfe7dopvy7vo.jpeg",
 "title": "Construction of the Golden Gate Bridge",
 "dir": "n",
 "geo": [
 37.813971,
 -122.47804
 ],
 "year": 1935
 },
 {
 "cid": 217640,
 "file": "z/d/q/zdqrca2bjarfp07a57.jpg",
 "s": 5,
 "year": 1984,
 "title": "Golden Gate Bridge cable seat",
 "dir": "e",
 "geo": [
 37.814098,
 -122.478182
 ]
 },
 {
 "s": 5,
 "cid": 1183693,
 "file": "d/9/b/d9b1ge4rppv4bfbzxd.jpg",
 "title": "Opening of the Golden Gate Bridge",
 "geo": [
 37.813959,
 -122.478133
 ],
 "year": 1937,
 "dir": "s"
 },
 {
 "cid": 217639,
 "file": "3/2/j/32jcf9in32imvdfpzx.jpg",
 "s": 5,
 "year": 1984,
 "title": "San Francisco from Golden Gate Bridge",
 "dir": "s",
 "geo": [
 37.814112,
 -122.478353
 ]
 },
 {
 "cid": 186038,
 "file": "u/8/i/u8iqv58ylg9wgzwgbs.jpg",
 "s": 5,
 "year": 1988,
 "title": "Golden Gate Bridge",
 "dir": "ne",
 "geo": [
 37.816022,
 -122.479992
 ]
 },
 {
 "s": 5,
 "cid": 449470,
 "file": "7/b/i/7bi9g0kfwouz0oho3b.jpeg",
 "title": "Golden Gate Bridge construction",
 "geo": [
 37.825334,
 -122.479094
 ],
 "year": 1935,
 "dir": "s"
 },
 {
 "s": 5,
 "cid": 449461,
 "file": "c/d/i/cdi0m6d1c4233j8jdn.jpeg",
 "title": "Two workers on the saddle atop the Golden Gate Bridge's Marin Tower",
 "year": 1934,
 "dir": "sw",
 "geo": [
 37.825588,
 -122.478992
 ]
 },
 {
 "cid": 191510,
 "file": "s/7/o/s7o8n6gjlo0n47a4ed.jpg",
 "s": 5,
 "year": 1937,
 "title": "Golden Gate Bridge opening",
 "dir": "n",
 "geo": [
 37.813174,
 -122.477731
 ]
 }
 ]
 },
 "rid": "7crxtti1q3"
 }
 */
