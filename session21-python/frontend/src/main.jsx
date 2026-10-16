import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';

const API = '/api/tickets';
const statuses = { TODO: 'Open', IN_PROGRESS: 'Working', DONE: 'Resolved' };
const categories = ['ACCESS', 'NETWORK', 'APPLICATION', 'HARDWARE', 'OTHER'];

async function request(url, options) {
  const response = await fetch(url, options);
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(typeof data.detail === 'string' ? data.detail : `Request failed (${response.status})`);
  }
  return response.status === 204 ? null : response.json();
}

function App() {
  const [tickets, setTickets] = useState([]);
  const [stats, setStats] = useState({ total: 0, todo: 0, inProgress: 0, done: 0 });
  const [filter, setFilter] = useState('ALL');
  const [category, setCategory] = useState('ALL');
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const load = async () => {
    try {
      const [items, totals] = await Promise.all([request(API), request(`${API}/stats`)]);
      setTickets(items);
      setStats(totals);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => { load(); }, []);

  const visible = tickets.filter(t => (filter === 'ALL' || t.status === filter) && (category === 'ALL' || t.category === category));
  const update = async (ticket) => {
    setSaving(true);
    setError('');
    try {
      const next = ticket.status === 'TODO' ? 'IN_PROGRESS' : ticket.status === 'IN_PROGRESS' ? 'DONE' : 'TODO';
      await request(`${API}/${ticket.id}`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ status: next }) });
      await load();
    } catch (e) { setError(e.message); }
    finally { setSaving(false); }
  };
  const remove = async (ticket) => {
    if (!window.confirm(`Delete ticket #${ticket.id}?`)) return;
    setSaving(true);
    setError('');
    try { await request(`${API}/${ticket.id}`, { method: 'DELETE' }); await load(); }
    catch (e) { setError(e.message); }
    finally { setSaving(false); }
  };
  const create = async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const fields = new FormData(form);
    setSaving(true);
    setError('');
    try {
      await request(API, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: fields.get('title').trim(), description: fields.get('description'), priority: fields.get('priority'),
          requester: fields.get('requester').trim(), category: fields.get('category'), assignee: fields.get('assignee').trim() || 'Unassigned', status: 'TODO' })
      });
      form.reset();
      setShowForm(false);
      await load();
    } catch (e) { setError(e.message); }
    finally { setSaving(false); }
  };

  return <div className="app">
    <aside className="sidebar">
      <div className="brand"><span className="brand-mark">H</span><div><b>HeroDesk</b><small>IT Support Workspace</small></div></div>
      <nav aria-label="Ticket views">
        <a href="#tickets" className={filter === 'ALL' ? 'active' : ''} onClick={() => setFilter('ALL')}>All tickets</a>
        <a href="#tickets" className={filter === 'TODO' ? 'active' : ''} onClick={() => setFilter('TODO')}>Open queue</a>
        <a href="#tickets" className={filter === 'DONE' ? 'active' : ''} onClick={() => setFilter('DONE')}>Resolved</a>
      </nav>
      <div className="side-bottom">
        <div className="upgrade"><strong>Support starts here.</strong><p>Report an issue, assign an engineer, and track it through resolution.</p></div>
        <div className="profile"><div className="avatar">SR</div><div><b>Sachith Reddy</b><small>Support Engineer</small></div></div>
      </div>
    </aside>
    <main className="main">
      <header><div><p className="eyebrow">SERVICE DESK / OVERVIEW</p><h1>Support workspace</h1><p className="muted">Track access requests, outages, and everyday IT issues.</p></div>
        <button className="primary" onClick={() => { setError(''); setShowForm(true); }}>+ New ticket</button></header>
      {error && !showForm && <div className="alert" role="alert">{error} <button onClick={() => { setError(''); load(); }}>Retry</button></div>}
      <section className="stats" aria-label="Ticket statistics">
        <Stat label="Total tickets" value={stats.total} icon="#" /><Stat label="Open" value={stats.todo} icon="O" />
        <Stat label="Working" value={stats.inProgress} icon="~" /><Stat label="Resolved" value={stats.done} icon="+" />
      </section>
      <section className="content-grid">
        <div className="panel tasks-panel" id="tickets">
          <div className="panel-head"><div><h2>Support tickets</h2><p className="muted">Advance a ticket from Open to Working to Resolved.</p></div>
            <div className="filters">{['ALL', ...Object.keys(statuses)].map(s => <button key={s} className={filter === s ? 'selected' : ''} onClick={() => setFilter(s)}>{statuses[s] || 'All'}</button>)}</div>
          </div>
          <div className="category-filter"><label>Category<select value={category} onChange={e => setCategory(e.target.value)}><option value="ALL">All categories</option>{categories.map(c => <option key={c}>{c}</option>)}</select></label></div>
          {loading ? <div className="empty">Loading tickets...</div> : <div className="table-wrap"><table>
            <thead><tr><th>Ticket / Requester</th><th>Assignee</th><th>Priority</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>{visible.map(t => <tr key={t.id}>
              <td><div className="task-title"><span className={`dot ${t.status.toLowerCase()}`}></span><div><b>#{t.id} {t.title}</b><small>{t.category} / {t.requester}</small><small>{t.description}</small></div></div></td>
              <td>{t.assignee}</td><td><span className={`priority ${t.priority.toLowerCase()}`}>{t.priority}</span></td>
              <td><span className={`status ${t.status.toLowerCase()}`}>{statuses[t.status]}</span></td>
              <td><button className="icon-btn" disabled={saving} onClick={() => update(t)} aria-label={`Advance ticket ${t.id}`} title={t.status === 'DONE' ? 'Reopen ticket' : 'Advance status'}>Next</button>{' '}
                <button className="icon-btn" disabled={saving} onClick={() => remove(t)} aria-label={`Delete ticket ${t.id}`}>Delete</button></td>
            </tr>)}</tbody></table>{!visible.length && <div className="empty">No tickets in this view. Create one to get started.</div>}</div>}
        </div>
        <aside className="panel activity"><div className="panel-head"><div><h2>Recent requests</h2><p className="muted">The latest tickets in your workspace.</p></div></div>
          {tickets.slice(0, 5).map(t => <div className="activity-row" key={t.id}><span className="activity-icon">#{t.id}</span><div><b>{t.title}</b><small>{t.requester} / {statuses[t.status]}</small></div></div>)}
          {!tickets.length && <div className="empty">Your support queue is empty.</div>}
        </aside>
      </section>
      {showForm && <div className="modal-backdrop"><form className="modal" onSubmit={create} aria-label="Create support ticket">
        <div className="modal-head"><div><p className="eyebrow">NEW SUPPORT REQUEST</p><h2>Create a ticket</h2></div><button type="button" className="close" aria-label="Close" onClick={() => setShowForm(false)}>x</button></div>
        {error && <div className="alert" role="alert">{error}</div>}
        <label>Issue title<input name="title" required maxLength={200} placeholder="e.g. Cannot connect to office VPN" /></label>
        <label>Description<textarea name="description" placeholder="What happened, and how does it affect your work?" /></label>
        <div className="form-row"><label>Requester<input name="requester" required maxLength={120} placeholder="Your name or team" /></label><label>Category<select name="category">{categories.map(c => <option key={c}>{c}</option>)}</select></label></div>
        <div className="form-row"><label>Priority<select name="priority" defaultValue="MEDIUM"><option>LOW</option><option>MEDIUM</option><option>HIGH</option></select></label><label>Assignee<input name="assignee" maxLength={120} defaultValue="Sachith Reddy" /></label></div>
        <button className="primary full" disabled={saving}>{saving ? 'Saving...' : 'Create ticket'}</button>
      </form></div>}
    </main>
  </div>;
}

function Stat({ label, value, icon }) {
  return <div className="stat"><div className="stat-icon">{icon}</div><div><small>{label}</small><strong>{value}</strong><span>From the support database</span></div></div>;
}
createRoot(document.getElementById('root')).render(<App />);
