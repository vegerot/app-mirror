import CoreGraphics

/// Target coordinates use a top-left origin; mirror coordinates use bottom-left.
struct CoordinateMap {
    let target: CGRect
    let mirror: CGSize

    func remotePoint(_ local: CGPoint) -> CGPoint {
        guard mirror.width > 0, mirror.height > 0 else { return target.origin }
        return CGPoint(x: target.minX + local.x / mirror.width * target.width,
                       y: target.minY + (1 - local.y / mirror.height) * target.height)
    }

    func localFrame(_ remote: CGRect) -> CGRect? {
        guard target.width > 0, target.height > 0,
              remote.width > 0, remote.height > 0, remote.intersects(target) else { return nil }
        return CGRect(x: (remote.minX - target.minX) / target.width * mirror.width,
                      y: (target.maxY - remote.maxY) / target.height * mirror.height,
                      width: remote.width / target.width * mirror.width,
                      height: remote.height / target.height * mirror.height)
    }
}
