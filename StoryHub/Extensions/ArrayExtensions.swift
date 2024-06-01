extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map { startIndex in
            let endIndex = Swift.min(startIndex + size, self.count)
            return Array(self[startIndex ..< endIndex])
        }
    }
}
