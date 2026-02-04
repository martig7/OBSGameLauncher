import { NavLink } from 'react-router-dom'

function Navbar() {
  return (
    <nav className="navbar">
      <div className="navbar-brand">
        <span>Game Recordings</span>
      </div>
      <div className="nav-tabs">
        <NavLink
          to="/"
          className={({ isActive }) => `nav-tab ${isActive ? 'active' : ''}`}
        >
          Recordings
        </NavLink>
        <NavLink
          to="/clips"
          className={({ isActive }) => `nav-tab ${isActive ? 'active' : ''}`}
        >
          Clips
        </NavLink>
        <NavLink
          to="/storage"
          className={({ isActive }) => `nav-tab ${isActive ? 'active' : ''}`}
        >
          Storage
        </NavLink>
      </div>
    </nav>
  )
}

export default Navbar
